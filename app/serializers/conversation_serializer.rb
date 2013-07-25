class ConversationSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :url, :updated_at, :firebase_token, :code, :title, :munged_title, :call_to_action,
             :current_timestamp, :privacy, :published, :starts_at, :ends_at, :list, :tags, :notification_request
  has_many :comments

  def include_comments?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def url
    api_conversation_url(object)
  end

  def munged_title
      object.title_comment.try{ |title_comment| title_comment.text.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]}
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

  def tags
    object.tags.map(&:name)
  end

  def include_notification_request?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def notification_request
    request = NotificationRequest.where(conversation_id: object.id, user_id: current_user.try{ |u| u.id}||0 ).first
    if request.nil?
      {immediate: 'mine', daily: true, default: true}
    else
      {
          immediate: (request.immediate_all ? 'every' : request.immediate_me ? 'mine' : 'none'),
          daily: request.send_email_at ? true : false
      }
    end
  end


end
