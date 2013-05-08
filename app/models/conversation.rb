class Conversation < ActiveRecord::Base
  def active_model_serializer
    ConversationSerializer
  end

  attr_accessible :question_id, :status

  belongs_to :question
  has_many  :comments, -> { includes :author }
  has_many  :conversation_comments, -> { includes :author }
  has_many :summary_comments, -> { includes :author }

  validates :question_id, :status, :presence => true

end
