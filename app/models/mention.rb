class Mention < ActiveRecord::Base
  attr_accessible :comment_id, :version, :user_id, :mentioned_user_id

  belongs_to :comment
  belongs_to :user

end
