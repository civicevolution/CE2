class Reply < ActiveRecord::Base
  attr_accessible :comment_id, :reply_to_id, :version, :quote, :author, :code

  belongs_to :reply_comments, class_name: "Comment", foreign_key: :comment_id
  belongs_to :reply_to_comments, class_name: "Comment", foreign_key: :reply_to_id

end
