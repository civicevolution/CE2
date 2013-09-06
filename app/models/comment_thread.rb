class CommentThread < ActiveRecord::Base

  belongs_to :child_comments, class_name: "Comment", foreign_key: :child_id
  belongs_to :parent_comments, class_name: "Comment", foreign_key: :parent_id

  before_create :set_order_id_for_child_comment

  def set_order_id_for_child_comment
    # set order_id to the max order_id +1 for this conversation, starting at 1
    self.order_id = CommentThread.where(parent_id: self.parent_id).maximum(:order_id).try{ |max| max + 1 } || 1
  end


end
