class ConversationGroupDataSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :updated_at, :code, :title, :privacy,
             :current_timestamp, :role

  has_many :table_comments

  def table_comments
    if current_user
      object.table_comments.where(user_id: current_user.id)
    end
  end

  def title
    TitleComment.find_by(conversation_id: object.id).try{ |title_comment| title_comment.text} || 'Untitled'
  end

  def current_timestamp
    Time.new.to_i
  end

  def role
    Ability.abilities(current_user, 'Conversation', object.id)
  end

end
