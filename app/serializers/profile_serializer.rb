class ProfileSerializer < ActiveModel::Serializer
  self.root = false

  attributes :profile_id, :user_id, :first_name, :last_name, :email, :photo_code

  def profile_id
    object.id
  end

  def first_name
    object.user.first_name
  end

  def last_name
    object.user.last_name
  end

  def email
    object.user.email
  end

  def photo_code
    if object.photo_file_name
      object.user.code
    else
      'default-user'
    end
  end

end
