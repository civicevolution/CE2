class ParkedCommentSerializer < ActiveModel::Serializer
  attributes :updated_at, :conversation_id, :parked_ids,
             :code, :first_name, :last_name, :name

  def code
    object.user.code
  end

  def first_name
    object.user.first_name
  end

  def last_name
    object.user.last_name
  end

  def name
    object.user.name
  end

end
