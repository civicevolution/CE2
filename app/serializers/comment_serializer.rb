class CommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :url, :first_name, :last_name, :updated_at, :purpose,
             :version, :ratings_cache, :my_rating, :number_of_votes, :sm1, :sm2, :sm3, :sm4, :sm5,
             :editable_by_user, :name_count, :code,
             :replies, :reply_to_targets, :bookmark
             #:reply_comments, :reply_to_comments

   def url
    api_comment_url(object)
  end

  def first_name
    object.author.first_name
  end

  def last_name
    object.author.last_name
  end

  def name_count
    object.author.name_count
  end

  def code
    object.author.code
  end

  def number_of_votes
    object.ratings_cache.inject{|sum,x| sum + x }
  end

  def purpose
    object.purpose || 'Comment'
  end

  def replies
    object.replies.map do |reply|
      {id: reply.comment_id, version: reply.version}
    end
  end

  def reply_to_targets
    object.reply_to_targets.map do |reply|
      {id: reply.reply_to_id, version: reply.version, author: reply.author, code: reply.code, quote: reply.quote}
    end
  end

  def sm1
    object.author.profile.try{|profile| profile.photo.url(:sm1)}
  end

  def sm2
    object.author.profile.try{|profile| profile.photo.url(:sm2)}
  end

  def sm3
    object.author.profile.try{|profile| profile.photo.url(:sm3)}
  end

  def sm4
    object.author.profile.try{|profile| profile.photo.url(:sm4)}
  end

  def sm5
    object.author.profile.try{|profile| profile.photo.url(:sm5)}
  end

  def editable_by_user
    ((defined? current_user).nil? || current_user.nil?) ? false : object.editable_by_user?(current_user)
  end

end
