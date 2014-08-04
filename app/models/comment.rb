require 'differ'
class Comment < ActiveRecord::Base
  include Modules::PostProcess

  def active_model_serializer
    CommentSerializer
  end

  def serializable_hash options=nil
    super.merge "type" => type
  end

  attr_accessor :my_rating, :conversation_code, :in_reply_to_id, :in_reply_to_version, :bookmark, :auth_type,
                :pro_votes, :con_votes, :post_process_disabled, :tag_ids

  attr_accessible :type, :user_id, :conversation_id, :text, :version, :status, :order_id, :purpose,
                  :conversation_code, :in_reply_to_id, :in_reply_to_version, :published, :auth_type, :tag_name,
                  :pro_votes, :con_votes, :elements, :tag_ids

  has_paper_trail class_name: 'CommentVersion', on: [:update], only: [:text, :order_id], version: :paper_trail_version,
                  skip: [:type, :user_id, :conversation_id, :status, :order_id, :purpose, :references, :created_at, :updated_at, :ratings_cache]


  belongs_to :author,  -> { select :id, :first_name, :last_name, :code, :name, :name_count}, :class_name => 'User', :foreign_key => 'user_id',  :primary_key => 'id'  #, photo_file_name'

  belongs_to :conversation

  has_many :ratings, :as => :ratable

  has_one :reply

  has_one :pro_con_vote

  has_many :reply_to_targets, class_name: 'Reply', foreign_key: :comment_id
  has_many :reply_to_comments, through: :reply_to_targets, source: :reply_to_comments

  has_many :replies, class_name: 'Reply', foreign_key: :reply_to_id
  has_many :reply_comments, through: :replies, source: :reply_comments

  has_many :parent_targets, class_name: 'CommentThread', foreign_key: :child_id
  has_many :parent_comments, through: :parent_targets, source: :parent_comments

  has_many :child_targets, -> { order 'order_id ASC' }, class_name: 'CommentThread', foreign_key: :parent_id
  has_many :child_comments, through: :child_targets, source: :child_comments

  has_many :mentions, dependent: :delete_all

  has_many :comment_tag_assignments, dependent: :delete_all

  after_initialize :read_previous_text_on_init
  before_update :increment_comment_version
  before_create :initialize_ratings_cache_to_zeros
  
  def read_previous_text_on_init
    @text = text
  end

  def increment_comment_version
    self.version += 1 if text != @text
    true
  end

  def initialize_ratings_cache_to_zeros
    self.ratings_cache = [0,0,0,0,0,0,0,0,0,0]
    true
  end

  validates :type, :conversation_id, :version, :status, :order_id, :presence => true
  validates :purpose, presence: { message: 'Must select what you will share' }
  validates :text, length: { minimum: 2, too_short: "Comment must be at least %{count} characters"}
  validates :tag_name, length: { maximum: 20, too_long: "Must be less than %{count} characters" }
  #validates :text, length: { maximum: 1500, too_long: "Must be less than %{count} characters" }
  validates :user_id, :presence => true, unless: Proc.new { |c| c.auth_type == :post_unknown }
  validate :do_not_save_comment_for_post_unknown, on: :create

  validate :check_the_reasons, unless: Proc.new { |c| c.type == 'TitleComment' }

  def check_the_reasons
    # make sure there are no empty reasons
    reasons = []
    if self.elements && self.elements['reasons']
      self.elements['reasons'].each do |reason|
        if reason['type'] == ""
          if reason['text'] != ""
            errors.add(:auth_type, "You must select a reason")
            return false
          end
          # I'm ignoring this reason as it has no type and no text
        else
          reasons.push reason
        end
        if reasons.length > 0
          self.elements['reasons'] = reasons
        else
          self.elements['reasons'] = nil
        end
      end
    end
    conversation = self.conversation
    if conversation.details && conversation.details['use_element'] && self.elements
      self.text = generate_text_from_element(conversation.details, self.elements)
    end

  end

  def generate_text_from_element(details, elements)
    # ignore reasons that are not filled in
    strs = []
    elements.each_pair do |key,value|
      #puts "pairs #{key}: #{value}, type: #{value.class.to_s}"
      case key
        when 'recommendation_type'
          #value_string = details['comment_types'].detect{|com_type| com_type['key'] == value}.try{|com_type| com_type['text']} || 'unknown comment type'
          #strs.push( "**_#{value_string}_**\n\n" )
          strs.push( "**_#{value}_**\n\n" )
        when 'suggestion'
          strs.push( "**_Suggested change_**  \n" )
          strs.push( "#{value}\n\n" )
        when 'reasons'
          if !value.nil?
            strs.push( "**_Reasons_**\n\n" )
            value.each do |reason|
              #puts "reason: #{reason}"
              strs.push( "* **_#{reason['type']}:_** #{reason[ 'text']}\n" )
            end
          else
            strs.push( "**_No reasons given_**\n\n" )
          end
      end
    end
    strs.join('')
  end


  def do_not_save_comment_for_post_unknown
    if auth_type == :post_unknown
      errors.add(:auth_type, "Cannot save comment with auth_type :post_unknown")
      return false
    end
    return true
  end

  def is_new_comment?
    !persisted?
  end

  def history_diffs

    Differ.format = :html

    # create an array of the version details
    # extract the version #, text and time from the comment_versions table using reify
    version_details = self.versions.map do |ver|
      com_ver = ver.reify
      { text: com_ver.text, version: com_ver.version, created_at: ver.created_at}
    end

    # I want to display newest version and diffs first
    version_details.reverse!

    #process the version details into an array of diffs
    # for each version generate the diff with from the next version, if it exists

    # first diff is the current text
    diffs = [ { version: 'Current', html_diff: self.text, created_at: self.updated_at } ]

    # next diff is between current text and the first stored version
    diffs << { version: 'Current',
               html_diff: Differ.diff_by_word(self.text, version_details[0][:text]).to_s,
               created_at: self.created_at }

    # now iterate through the remaining versions, and then show initial version
    version_details.each_with_index do |ver,i|
      prev_ver = version_details[i+1]
      if prev_ver
        #puts "i: #{i}, ver: #{ver[:version]}: #{ver[:text]} PREV ver: #{prev_ver[:version]}: #{prev_ver[:text]}"
        diffs << { version: ver[:version],
                   #html_diff: "new: #{ver[:text]}, old: #{prev_ver[:text]}",
                   html_diff: Differ.diff_by_word(ver[:text], prev_ver[:text]).to_s,
                   created_at: ver[:created_at] }
      else
        #puts "i: #{i}, ver: #{ver[:version]}: #{ver[:text]} NO PREV ver!"
        diffs << { version: 'Original', html_diff: ver[:text], created_at: ver[:created_at] }
      end
    end

    diffs

  end

  def editable_by_user?(user)
    user_id == user.id
  end

  def accept
    Rails.logger.debug "Accept this comment: #{self.inspect}"

    self.update_attributes( published: true, status: "approved" )

    log = new_log_record
    log.review_details = { comment_action: 'accepted'}
    log.save

    # send email notification to the author if they are confirmed
    author = User.find(self.user_id)
    if !author.confirmed_at.nil?
      ConversationMailer.delay.comment_accepted(author, self.conversation, self)
    end
  end


  def decline
    Rails.logger.debug "Decline this comment: #{self.inspect}"

    self.update_attributes( published: false, status: "declined" )

    log = new_log_record
    log.review_details = { comment_action: 'declined'}
    log.save

    # send email notification to the author if they are confirmed
    author = User.find(self.user_id)
    if !author.confirmed_at.nil?
      ConversationMailer.delay.comment_declined(author, self.conversation, log)
    end
  end

  def new_log_record
    log = LogReviewedComment.new
    attributes.each_pair do |key,value|
      case key
        when "id"
          log.comment_id = value
        when "created_at", "ratings_cache"
        when "updated_at"
          log.posted_at = value
        else
          log[key] = value
      end
    end
    log
  end

  def self.update_comment_order( id, ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      #Rails.logger.debug "update_comment_order ordered_ids: #{ordered_ids}, order_string: #{order_string} "

      sql =
          %Q|UPDATE comment_threads SET order_id = new_order_id
      FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,comment_id)	) t
      WHERE child_id = t.comment_id AND parent_id = #{id}|


      #Rails.logger.debug "update_comment_order with sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i }
      ids_order_id
    end
  end


  #protected
  def as_json_for_notification( action = "create" )
    #data = self.active_model_serializer.new( self ).as_json
    data = {
      comment: self.as_json,
      author: self.author.as_json,
      reply: self.reply.as_json,
      pro_con_vote: self.pro_con_vote
    }
    { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RoR-RT-Notification" }
  end

end
