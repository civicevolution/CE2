class SynthesisComment < Comment

  def active_model_serializer
    CommentSerializer
  end

  belongs_to :conversation

  before_validation :initialize_purpose_to_synthesis

  def initialize_purpose_to_synthesis
    self.purpose = "Synthesis" unless purpose
  end


  before_validation :set_order_id_for_new_synthesis_comment

  def set_order_id_for_new_synthesis_comment
    # set order_id to the max order_id +1 for this conversation, starting at 1
    return true unless self.order_id.nil?
    self.order_id = SynthesisComment.where(conversation_id: self.conversation_id).maximum(:order_id).try{ |max| max + 1 } || 1
  end

  validate :check_tag_ids
  after_save :update_tag_ids

  def check_tag_ids
    #Rails.logger.debug "check_tag_ids make sure 0 or 1 only, tag_ids: #{tag_ids}"
    if tag_ids && tag_ids.size > 1
      errors.add(:tag_ids, "Comment can only have one tag")
      return false
    end
  end

  def update_tag_ids
    #Rails.logger.debug "check if tag_ids defined"
    if !tag_ids.nil?
      #Rails.logger.debug "process the tag_ids to make sure it is up-to-date"
      CommentTagAssignment.updateCommentTagAssignments(self)
    end
  end

end