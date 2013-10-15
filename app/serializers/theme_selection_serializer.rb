class ThemeSelectionSerializer < ActiveModel::Serializer
  #attributes :code, :title,
  #           :current_timestamp, :privacy, :role, :votes, :allocated_points
  #has_many :final_themes

  attributes :votes, :conversations_list, :agenda_code, :title

  def include_final_themes?
    !object.final_themes.nil?
  end

  def title
    object.conversation.try{|conversation| conversation.title} ||''
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
