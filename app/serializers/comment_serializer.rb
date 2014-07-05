class CommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :url, :first_name, :last_name, :updated_at, :purpose,
             :version, :ratings_cache, :my_rating, :number_of_votes, :photo_code,
             :editable_by_user, :name, :code, :published, :status,
             :replies, :reply_to_targets, :bookmark, :user_id
             #:reply_comments, :reply_to_comments

   def url
    api_comment_url(object)
  end

  def first_name
    object.author.first_name
  end

  def last_name
    if object.author.name_count.nil? || object.author.name_count  == 1
      object.author.last_name
    else
      "#{object.author.last_name}[#{object.author.name_count}]"
    end
  end

  def name
    if object.author.name_count.nil? || object.author.name_count  == 1
      "#{object.author.first_name}_#{object.author.last_name}"
    else
      "#{object.author.first_name}_#{object.author.last_name}_#{object.author.name_count}"
    end
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

  def photo_code
    if object.author.profile && object.author.profile.photo_file_name
      object.author.code
    else
      'default-user'
    end
  end

  def editable_by_user
    (defined?(current_user).nil? || current_user.nil?) ? false : object.editable_by_user?(current_user)
  end

end
