class ConversationSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :url, :updated_at, :firebase_token, :code, :title, :munged_title, :current_timestamp
  has_many :comments

  def include_comments?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def url
    api_conversation_url(object)
  end

  def munged_title
      object.title_comment.try{ |title_comment| title_comment.text.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase} || 'untitled-conversation'
  end

  def title
    object.title_comment.try{ |title_comment| title_comment.text} || 'Untitled conversation'
  end

  def current_timestamp
    Time.new.to_i
  end


end
