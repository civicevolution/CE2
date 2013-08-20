class UserSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :first_name, :last_name, :name, :email, :confirmed, :small_photo_url, :sm1, :sm2, :sm3, :sm4

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
