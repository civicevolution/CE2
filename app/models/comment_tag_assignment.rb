class CommentTagAssignment < ActiveRecord::Base

  attr_accessible :tag_id, :tag_text, :comment_id, :user_id, :star, :conversation_id, :conversation_code
  attr_accessor :tag_text, :conversation_code

  belongs_to :user
  belongs_to :conversation
  belongs_to :comment
  belongs_to :tag


  validate :assure_conversation_id, on: :create
  validate :assure_tag_id, on: :create
  validates_presence_of :comment_id, :tag_id

  def assure_conversation_id
    self.conversation_id = self.comment.conversation.id unless conversation_id
  end

  def assure_tag_id
    if self.tag_text
      tag = Tag.where(text: tag_text).first_or_create
      if !tag.errors.empty?
        errors[:base] << "Tag with text: #{tag_text} could not be created"
        errors[:base] << "Tag reported error: #{tag.errors.messages[:text].join(', ')}"
        return false
      end
      self.tag_id = tag.id
    elsif self.tag_id
      tag = Tag.find_by(id: tag_id)
      if tag.nil?
        errors[:base] << "Tag with id: #{tag_id} not found"
        return false
      end
    end
  end

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
    Rails.logger.debug "realtimePublish action: #{action}"
    self.conversation_code = Comment.find(self.comment_id).conversation.code unless conversation_code

    data = self.as_json
    data['tag_text'] = tag_text unless tag_text.nil?
    message = { class: self.class.to_s, action: action, data: data, updated_at: Time.now.getutc, source: "RoR-RT-Notification" }
    channel = "/#{conversation_code}/tags"
    Modules::FayeRedis::publish(message,channel)
  end

end

