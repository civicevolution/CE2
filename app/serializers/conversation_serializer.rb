class ConversationSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :id, :url, :question, :updated_at
  has_many :comments

  def url
    api_conversation_url(object)
  end

  def question
    object.question.text
  end

end