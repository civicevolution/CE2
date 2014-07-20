class CommentTagAssignment < ActiveRecord::Base

  attr_accessible :tag_id, :tag_text, :comment_id, :user_id, :star, :conversation_id
  attr_accessor :tag_text

  belongs_to :user
  belongs_to :conversation
  belongs_to :comment
  belongs_to :tag


  validate :assure_conversation_id, on: :create
  validate :assure_tag_id, on: :create

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

end

