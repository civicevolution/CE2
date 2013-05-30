class UserSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :first_name, :last_name, :email, :small_photo_url, :sm1, :sm2, :sm3, :sm4

  def small_photo_url
    object.profile.try{|profile| profile.photo.url(:sm)} || '/assets/default-user.jpg'
  end

  def sm1
    object.profile.try{|profile| profile.photo.url(:sm1)} || '/assets/default-user.jpg'
  end

  def sm2
    object.profile.try{|profile| profile.photo.url(:sm2)} || '/assets/default-user.jpg'
  end

  def sm3
    object.profile.try{|profile| profile.photo.url(:sm3)} || '/assets/default-user.jpg'
  end

  def sm4
    object.profile.try{|profile| profile.photo.url(:sm4)} || '/assets/default-user.jpg'
  end

end
