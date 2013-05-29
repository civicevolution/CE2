class CommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :url, :first_name, :last_name, :updated_at, :version, :ratings_cache, :my_rating, :number_of_votes, :small_user_photo_url

  has_many :attachments

  def url
    api_comment_url(object)
  end

  def first_name
    object.author.first_name
  end

  def last_name
    object.author.last_name
  end

  def number_of_votes
    object.ratings_cache.inject{|sum,x| sum + x }
  end

  def small_user_photo_url
    object.author.profile.try{|profile| profile.photo.url(:sm)} || '/assets/default-user.jpg'
  end

end
