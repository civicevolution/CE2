require 'securerandom'
class Conversation < ActiveRecord::Base
  def active_model_serializer
    ConversationSerializer
  end

  attr_accessible :user_id, :status, :starts_at, :privacy, :agenda_id
  attr_accessor :display_mode, :final_themes, :session_id

  belongs_to :agenda

  has_one :title_comment #, -> { includes author: :profile   }
  has_one :call_to_action_comment, -> { includes author: :profile   }
  has_many  :comments, -> { includes [{author: :profile}, :replies, :reply_to_targets, :child_targets, :parent_targets, :pro_con_vote] }

  has_many  :theme_page_comments, -> { includes [:author, :child_targets, :parent_targets, :pro_con_vote] }, class_name: "Comment"

  has_many  :conversation_comments, -> { includes author: :profile }
  has_many :summary_comments, -> { includes author: :profile }

  has_many :table_comments, ->{ includes [:author, :pro_con_vote, :parent_targets] }

  has_many :theme_comments, ->{ includes [:author, :child_targets, :parent_targets] }

  has_many :attachments, :as => :attachable

  has_and_belongs_to_many :tags

  has_many :notification_requests

  has_many :flagged_items, class_name: 'FlaggedItem'

  has_many :guest_post_items, class_name: 'GuestPost'

  has_many :invites, -> {includes :sender}

  has_many :roles, -> {includes :users}, class_name: 'Role', primary_key: :id, foreign_key: :resource_id

  has_many :parked_comments, -> {includes :user}

  validates :status, presence: true
  validate :conversation_code_is_unique, on: :create
  before_create :initialize_conversation
  after_initialize :initialize_display_mode_to_show_all
  after_find :initialize_display_mode_to_show_all

  def displayed_comments
    if display_mode == :show_all
      comments
    else
      comments.where("type != 'ConversationComment'")
    end
  end

  def initialize_display_mode_to_show_all
    self.display_mode = :show_all
  end

  def conversation_code_is_unique
    self.code = Conversation.create_random_conversation_code
    while( Conversation.where(code: self.code).exists? ) do
      self.code = Conversation.create_random_conversation_code
    end
  end

  def self.create_random_conversation_code
    # I want each conversation to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...10).map{ o[rand(o.length)] }.join
  end

  def initialize_conversation
    self.privacy = CONVERSATION_PROPERTIES['privacy'].dup
    self.list = false
    self.status = 'new'
    self.starts_at = Time.now
    self.ends_at = (self.starts_at + (CONVERSATION_PROPERTIES['duration_in_days']).days).end_of_day
  end

  def self.update_comment_order( code, ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
%Q|UPDATE comments SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,comment_id)	) t
WHERE id = t.comment_id AND conversation_id = (SELECT id FROM conversations WHERE code = '#{code}') |
      Rails.logger.debug "update_comment_order with sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      # the order_ids start from 1, not 0
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i+1 }
      ids_order_id
    end
  end

  def update_tags user, new_tags
    # keep track of any current tags that are not included in the param for new tags
    current_tags = self.tags.map(&:name)
    new_tags.each do |tag_name|
      #Rails.logger.debug "Process tag_name: #{tag_name}"
      if current_tags.include? tag_name
        current_tags.delete(tag_name)
      else
        tag = Tag.where(name: tag_name).first_or_create do |tag|
          tag.user_id = user.id
        end
        self.tags << tag
      end
    end
    # now check if any of the current tags need to be removed
    current_tags.each do |tag_name|
      self.tags.delete( Tag.find_by(name: tag_name) )
    end

  end

  def update_privacy user, privacy_params
    privacy_params["confirmed_privacy"] = "true"
    if self.privacy['confirmed_schedule']
      privacy_params["confirmed_schedule"] = "true"
    end
    self.privacy = privacy_params
    self.save
  end

  def update_schedule user, dates
    Rails.logger.debug "Update the schedule start_date: #{dates[:start]} & end_date: #{dates[:end]}"
    self.starts_at = dates[:start]
    self.ends_at = dates[:end]
    # I have to trick Rails into updating the hstore by creating and assigning a new object
    privacy_params = {}
    self.privacy.each_pair{ |key,value| privacy_params[key] = value}
    privacy_params["confirmed_schedule"] = "true"
    self.privacy = privacy_params
    self.save
  end

  def publish user
    # validate conversation setup is complete and then publish
    self.status = 'ready'
    self.published = true
    self.save
    schedule_daily_report
    curator = User.find( self.user_id)
    ConversationMailer.delay.publish_notification_admin( curator, self)
    ConversationMailer.delay.publish_notification_curator( curator, self)
  end

  def schedule_daily_report
    first_run_time = Time.now.change(hour: self.daily_report_hour, minute: 0, second: 0)
    if first_run_time < Time.now + 1.hour
      first_run_time += 1.day
    end
    Conversation.delay(run_at: first_run_time).run_daily_report(self.id)
  end


  def munged_title
    self.title_comment.try{ |title_comment| title_comment.text.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]}
  end

  def title
    self.title_comment.try{ |title_comment| title_comment.text}
  end


  def self.run_daily_report conversation_id
    Rails.logger.debug "run_daily_report for con_id: #{conversation_id}"
    conversation = Conversation.find(conversation_id)
    report_time = Time.now
    requests = conversation.notification_requests.includes(:user).where(send_daily: true)
    # if there is at least one request for this conversation, collect the comments to be sent
    # Any SummaryComment or CallToAction comments that are new or are updated
    # Any ConversationComments that are new
    if requests.size > 0
      # Collect the comments
      time_to_run = Time.now
      comments = conversation.comments.
          where( %Q|type in ('SummaryComment', 'CallToActionComment') AND updated_at >= :last_report_time
          OR type = 'ConversationComment' AND created_at >= :last_report_time|,
          {last_report_time: conversation.last_report_sent_at || conversation.created_at} )
      # if there are any new comments to send, organize them and then iterate through the recipients
      if comments.size > 0
        # organize the comments into CTA, Summary and Conversation, order_id
        summary_comments = []
        conversation_comments = []
        call_to_action_comment = nil
        comments.each do |comment|
          case comment.type
          when "SummaryComment" then summary_comments.push comment
          when "ConversationComment" then conversation_comments.push comment
          when "CallToActionComment" then call_to_action_comment = comment
          end
        end
        # sort them by order_id
        summary_comments.sort{|a,b| a.order_id <=> b.order_id}
        conversation_comments.sort{|a,b| a.order_id <=> b.order_id}

        # iterate through the recipients
        requests.each do |request|
          Rails.logger.debug "Email daily report to #{request.user.email}"
          ConversationMailer.delay.
              periodic_report(request.user, conversation, summary_comments, conversation_comments, call_to_action_comment, report_time, "mcode")
        end
      end # comments.size > 0
    end # request.size > 0

    conversation.update_attribute(:last_report_sent_at,report_time)
    # create delayed_job request for tomorrow's daily report
    tomorrow_run_time = Time.now.change(hour: conversation.daily_report_hour, minute: 0, second: 0) + 1.day
    Conversation.delay(run_at: tomorrow_run_time).run_daily_report(conversation.id) unless !Rails.env.production?

  end

  def guest_posts
    # get the guest_posts for this conversation
    posts = self.guest_post_items
    user_ids = posts.map{|p| p.user_id}.compact.uniq
    users = User.where(id: user_ids).select('id, email, first_name, last_name, name, confirmed_at, code')

    emails = (posts.map{|p| p.email} + users.map{|u| u.email}).compact.uniq
    invites = Invite.where(email: emails).select('email, sender_user_id, created_at')

    posts.each do |post|
      if post.user_id
        #Rails.logger.debug "post.user_id: #{post.user_id}"
        user = users.detect{|u| u.id == post.user_id}
        post.email = user.email
        post.first_name = user.first_name
        post.last_name = user.last_name
        post.code = user.code
        if user.confirmed_at.nil?
          post.member_status = "Unconfirmed member"
        else
          post.member_status = "Confirmed member"
        end
      else
        post.member_status = 'Unknown guest'
        post.code = 'default-user'
      end
      invite = invites.detect{|i| i.email == post.email}
      if invite
        post.invited_at = invite.created_at
      end

    end

    posts.sort{|a,b| a.id <=> b.id}
  end

  def pending_comments
    self.comments.where(published: false, status: 'pre-review').order('id ASC').includes(:author)
  end

  def flagged_comments
    self.flagged_items.includes(:flagger, comment: :author)
  end

  def participants_roles
    participants_roles = []
    self.roles.each do |role|
      role.users.each do |user|
        #participants.push user
        name =
          if user.name_count.nil? || user.name_count  == 1
            "#{user.first_name} #{user.last_name}"
          else
            "#{user.first_name} #{user.last_name}[#{user.name_count}]"
          end

        participants_roles.push( {name: name, role: role.name, code: user.code} )
      end
    end
    participants_roles.sort{|a,b| a[:name] <=> b[:name]}
  end

  def update_role( user_code, new_role)
    user = User.find_by(code: user_code)
    #Rails.logger.debug "Update #{user.name} to #{new_role}"

    user.roles.where(resource_id: self.id, resource_type: self.class.to_s).each do |role|
      user.remove_role role.name, self
    end

    user.add_role new_role, self

  end

  def stats
    review_items_count = flagged_items.size +
      pending_comments.size +
      guest_post_items.size
    {review_items_count: review_items_count}
  end

  def themes
    self.theme_comments
  end

  def self.display_details(id)
    conversation = Conversation.find(id)
    puts "Conversation details:"
    puts "Title: #{conversation.title}"
    puts "id: #{conversation.id}"
    puts "code: #{conversation.code}"
    conversation_details = conversation.details.try{|details| details.symbolize_keys} || {}
    #puts "details:\n#{JSON.pretty_generate(conversation_details)}"
    #puts "details:\n#{pp(conversation_details)}"
    puts "details:\n#{conversation_details}"
  end

  def self.adjust_details(id, key, value)
    conversation = Conversation.find(id)

    conversation_details = conversation.details.try{|details| details.symbolize_keys} || {}
    conversation_details[key.to_sym] = value

    conversation.update_attribute(:details, conversation_details)

    "updated conversation.details[#{key.to_sym}] = #{value}\n"
    Conversation.display_details(id)
  end

  def update_conversation(data)
    updates = []
    details = nil
    data.each_pair do |key, value|
      if key.to_s == 'title'
        title_comment = self.title_comment
        title_comment.post_process_disabled = true
        title_comment.update_attribute(:text, value)
      elsif self.attributes.has_key? key.to_s
        self.update_attribute(key, value)
        updates.push({key: key, value: value})
      else
        details ||= self.details.try{|details| details.symbolize_keys} || {}
        if value.nil?
          details.delete(key.to_sym)
        else
          details[key.to_sym] = value
        end
        updates.push({key: key, value: value})
      end
    end
    if details
      self.update_attribute(:details, {})
      self.update_attribute(:details, details)
    end
    updates
  end

end
