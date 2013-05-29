class UserSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :first_name, :last_name, :email, :small_photo_url

  def small_photo_url
    object.profile.try{|profile| profile.photo.url(:sm)} || '/assets/default-user.jpg'
  end

end
