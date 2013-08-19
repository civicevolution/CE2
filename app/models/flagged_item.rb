class FlaggedItem < ActiveRecord::Base

  attr_accessible :user_id, :conversation_id, :target_type, :target_id, :version, :category, :statement

  has_one :comment, foreign_key: :id, primary_key: :target_id
  has_one :flagger, foreign_key: :id, primary_key: :user_id, class_name: 'User'

  belongs_to :conversation

  def mark_flagged_as(flag_action)
    Rails.logger.debug "mark_flagged_as #{flag_action} this item: #{self.inspect}"

    unless flag_action == 'do nothing'
      self.comment.update_attributes( published: false, status: flag_action )
    end

    log = new_log_record
    log.review_details = { flagged_comment_review_action: flag_action}
    log.save

    self.destroy

    ## send email notification to the author if they are confirmed
    #author = User.find(self.user_id)
    #if !author.confirmed_at.nil?
    #  ConversationMailer.delay.comment_declined(author, self.conversation, log)
    #end
  end

  def new_log_record
    log = LogFlaggedItem.new
    attributes.each_pair do |key,value|
      case key
        when "id", "created_at", "ratings_cache"
        when "updated_at"
          log.posted_at = value
        else
          log[key] = value
      end
    end
    log
  end

end
