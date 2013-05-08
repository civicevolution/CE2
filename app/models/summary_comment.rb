class SummaryComment < Comment

  def active_model_serializer
    CommentSerializer
  end

  belongs_to :conversation



end