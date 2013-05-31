class ProfileSerializer < ActiveModel::Serializer
  self.root = false

  attributes :profile_id, :user_id, :first_name, :last_name, :email, :small_photo_url, :sm1, :sm2, :sm3, :sm4

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
    object.photo.try{|photo| photo.url(:sm1)} || '/assets/default-user.jpg'
  end

  def sm1
    object.photo.try{|photo| photo.url(:sm1)} || '/assets/default-user.jpg'
  end

  def sm2
    object.photo.try{|photo| photo.url(:sm2)} || '/assets/default-user.jpg'
  end

  def sm3
    object.photo.try{|photo| photo.url(:sm3)} || '/assets/default-user.jpg'
  end

  def sm4
    object.photo.try{|photo| photo.url(:sm4)} || '/assets/default-user.jpg'
  end

end