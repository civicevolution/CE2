class UserSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :first_name, :last_name, :name, :email, :confirmed, :code, :photo_code

  def last_name
    if object.name_count.nil? || object.name_count  == 1
      object.last_name
    else
      "#{object.last_name}[#{object.name_count}]"
    end
  end

  def name
    if object.name_count.nil? || object.name_count  == 1
      "#{object.first_name}_#{object.last_name}"
    else
      "#{object.first_name}_#{object.last_name}_#{object.name_count}"
    end
  end

  def confirmed
    !object.confirmed_at.nil?
  end

  def photo_code
    if object.profile && object.profile.photo_file_name
      object.code
    else
      'default-user'
    end
  end

end
