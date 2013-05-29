class ProfileSerializer < ActiveModel::Serializer
  self.root = false

  attributes :profile_id, :user_id, :first_name, :last_name, :email, :small_photo_url

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

  def small_photo_url
    object.photo.url(:sm)
  end

end
