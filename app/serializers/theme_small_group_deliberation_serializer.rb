class ThemeSmallGroupDeliberationSerializer < ActiveModel::Serializer
  attributes :updated_at, :code, :title,
             :current_timestamp, :privacy, :role

  has_many :theme_comments
  has_many :table_comments
  #has_many :parked_comments

  def title
    object.conversation.title
  end

  def code
    object.conversation.code
  end

  def privacy
    object.conversation.privacy
  end

  def current_timestamp
    Time.new.to_i
  end

  def role
    Ability.abilities(current_user, 'Conversation', object.conversation.id)
  end

end
