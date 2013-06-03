class ConversationSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :id, :url, :question, :updated_at, :firebase_token
  has_many :comments

  def include_comments?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def url
    api_conversation_url(object)
  end

  def include_question?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def question
      object.question.text
  end

end
