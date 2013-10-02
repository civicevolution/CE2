class ThemeSmallGroupThemeSerializer < ActiveModel::Serializer
  attributes :updated_at, :code, :title,
             :current_timestamp, :privacy, :role,
             :table_comments

  has_many :theme_comments
  has_many :coordinator_theme_comments
  #has_many :parked_comments

  def table_comments
    []
  end

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
