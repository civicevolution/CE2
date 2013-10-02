class SmallGroupDeliberationSerializer < ActiveModel::Serializer
  attributes :conversations_list, :title, :code, :current_timestamp, :privacy, :role

  has_many :table_comments

  def conversations_list
    object.conversations_list.map do |conversation|
      {
        component_code: object.code,
        code: conversation.code,
        title: conversation.title,
        munged_title: conversation.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]
      }
    end
  end

  def table_comments
    if current_user
      object.conversation.table_comments.where(user_id: current_user.id)
    end
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
