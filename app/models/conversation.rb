require 'securerandom'
class Conversation < ActiveRecord::Base
  def active_model_serializer
    ConversationSerializer
  end

  attr_accessible :user_id, :status
  attr_accessor :firebase_token

  has_one :title_comment, -> { includes author: :profile   }
  has_one :call_to_action_comment, -> { includes author: :profile   }
  has_many  :comments, -> { includes author: :profile   }
  has_many  :conversation_comments, -> { includes author: :profile }
  has_many :summary_comments, -> { includes author: :profile }

  has_many :attachments, :as => :attachable

  has_and_belongs_to_many :tags

  validate :conversation_code_is_unique, on: :create
  before_create :initialize_conversation

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

  def update_tags new_tags, user
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
      self.tags.delete( Tag.where(name: tag_name).first )
    end

  end

  def update_schedule dates
    Rails.logger.debug "Update the schedule start_date: #{dates[:start]} & end_date: #{dates[:end]}"
    self.starts_at = dates[:start]
    self.ends_at = dates[:end]
    self.save
  end

end
