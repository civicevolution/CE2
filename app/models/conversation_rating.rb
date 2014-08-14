class ConversationRating < ActiveRecord::Base

  attr_accessible :conversation_id, :user_id, :rating_type, :rating_data

  belongs_to :user
  belongs_to :conversation

  validates_presence_of :conversation_id, :user_id, :rating_type, :rating_data

  after_create do
    realtimePublish(:create)
  end

  after_update do
    realtimePublish(:update)
  end

  after_destroy do
    realtimePublish(:destroy)
  end

  def realtimePublish(action)
    #Rails.logger.debug "ConversationRating realtimePublish action: #{action}"
    data = self.as_json
    message = { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RoR-RT-Notification" }
    channel = "/#{self.conversation.code}/ratings"
    Modules::FayeRedis::publish(message,channel)
  end


end

