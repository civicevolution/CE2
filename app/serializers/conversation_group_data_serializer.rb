class ConversationGroupDataSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :url, :updated_at, :firebase_token, :code, :title, :munged_title,
             :current_timestamp, :privacy, :published, :starts_at, :ends_at, :list, :tags, :notification_request, :display_mode, :role
  has_many :displayed_comments

  def include_displayed_comments?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def include_role?
    !( scope && scope[:shallow_serialization_mode] )
  end

  def url
    api_conversation_url(object)
  end

  def munged_title
    object.displayed_comments.detect{|c| c.type == 'TitleComment'}.try{ |title_comment| title_comment.text.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]}
  end

  def title
    object.displayed_comments.detect{|c| c.type == 'TitleComment'}.try{ |title_comment| title_comment.text}
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
    request = NotificationRequest.find_by(conversation_id: object.id, user_id: current_user.try{ |u| u.id}||0 )
    if request.nil?
      {immediate: 'mine', daily: true, default: true}
    else
      {
          immediate: (request.immediate_all ? 'every' : request.immediate_me ? 'mine' : 'none'),
          daily: request.send_daily
      }
    end
  end

  def role
    Ability.abilities(current_user, 'Conversation', object.id)
  end

end
