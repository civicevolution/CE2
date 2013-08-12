require 'securerandom'
class Conversation < ActiveRecord::Base
  def active_model_serializer
    ConversationSerializer
  end

  attr_accessible :user_id, :status
  attr_accessor :firebase_token, :display_mode

  has_one :title_comment, -> { includes author: :profile   }
  has_one :call_to_action_comment, -> { includes author: :profile   }
  has_many  :comments, -> { includes [{author: :profile}, :replies, :reply_to_targets ] }
  has_many  :conversation_comments, -> { includes author: :profile }
  has_many :summary_comments, -> { includes author: :profile }

  has_many :attachments, :as => :attachable

  has_and_belongs_to_many :tags

  has_many :notification_requests

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

  def self.reorder_summary_comments( code, ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
%Q|UPDATE comments SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,comment_id)	) t
WHERE id = t.comment_id AND conversation_id = (SELECT id FROM conversations WHERE code = '#{code}') AND type = 'SummaryComment'|
      Rails.logger.debug "Use sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i }
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
              periodic_report(request.user, conversation, summary_comments, conversation_comments, call_to_action_comment, report_time, "mcode", "host")
        end
      end # comments.size > 0
    end # request.size > 0

    conversation.update_attribute(:last_report_sent_at,report_time)
    # create delayed_job request for tomorrow's daily report
    tomorrow_run_time = Time.now.change(hour: conversation.daily_report_hour, minute: 0, second: 0) + 1.day
    Conversation.delay(run_at: tomorrow_run_time).run_daily_report(conversation.id) unless !Rails.env.production?

  end



end
