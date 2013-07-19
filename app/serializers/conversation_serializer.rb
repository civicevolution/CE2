class ConversationSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :url, :updated_at, :firebase_token, :code, :title, :munged_title, :call_to_action,
             :current_timestamp, :privacy, :published, :ends_at, :list
  has_many :comments

  def include_comments?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def url
    api_conversation_url(object)
  end

  def munged_title
      object.title_comment.try{ |title_comment| title_comment.text.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase}
  end

  def title
    object.title_comment.try{ |title_comment| title_comment.text}
  end

  def call_to_action
    object.call_to_action_comment.try{ |call_to_action| call_to_action.text}
  end

  def current_timestamp
    Time.new.to_i
  end


end
