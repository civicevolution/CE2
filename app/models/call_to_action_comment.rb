class CallToActionComment < Comment

  def active_model_serializer
    CommentSerializer
  end

  belongs_to :conversation

  before_validation :set_order_id_for_call_to_action_comment, on: :create
  def set_order_id_for_call_to_action_comment
    self.order_id = 1
  end

end