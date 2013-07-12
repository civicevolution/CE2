class TitleComment < Comment

  def active_model_serializer
    CommentSerializer
  end

  belongs_to :conversation

  before_validation :set_order_id_for_title_comment, on: :create
  def set_order_id_for_title_comment
    self.order_id = 1
  end


end