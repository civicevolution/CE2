class CommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :url, :first_name, :last_name, :updated_at, :version, :ratings_cache, :my_rating, :number_of_votes

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

end
