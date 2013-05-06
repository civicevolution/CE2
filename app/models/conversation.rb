class Conversation < ActiveRecord::Base
  attr_accessible :question_id, :status

  belongs_to :question
  has_many  :conversation_comments
  has_many :summary_comments

  validates :question_id, :status, :presence => true

end
