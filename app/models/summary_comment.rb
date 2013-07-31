class SummaryComment < Comment

  def active_model_serializer
    CommentSerializer
  end

  belongs_to :conversation

  before_create :initialize_purpose_to_summary

  def initialize_purpose_to_summary
    self.purpose = "Summary"
  end


  before_validation :set_order_id_for_new_summary_comment

  def set_order_id_for_new_summary_comment
    # set order_id to the max order_id +1 for this conversation, starting at 1
    return true unless self.order_id.nil?
    self.order_id = SummaryComment.where(conversation_id: self.conversation_id).maximum(:order_id).try{ |max| max + 1 } || 1
  end


end