class TableComment < Comment

  def active_model_serializer
    TableCommentSerializer
  end

  belongs_to :conversation

  before_validation :set_order_id_for_new_table_comment

  validates :pro_votes, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: 'Must enter a number for members in favor' }
  validates :con_votes, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: 'Must enter a number for members opposed' }

  after_create  :record_pro_con_votes
  after_update  :update_pro_con_votes


  def record_pro_con_votes
    self.create_pro_con_vote pro_votes: self.pro_votes, con_votes: self.con_votes
  end

  def update_pro_con_votes
    if self.pro_con_vote
      self.pro_con_vote.update_columns({ pro_votes: self.pro_votes, con_votes: self.con_votes})
    else
      self.create_pro_con_vote pro_votes: self.pro_votes, con_votes: self.con_votes
    end
  end

  def set_order_id_for_new_table_comment
    # set order_id to the max order_id +1 for this conversation, starting at 1
    return true unless self.order_id.nil?
    self.order_id = TableComment.where(conversation_id: self.conversation_id).maximum(:order_id).try{ |max| max + 1 } || 1
  end

end