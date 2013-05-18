class CommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :url, :first_name, :last_name, :updated_at, :version, :vote_counts

  def vote_counts
    # [12, 5, 8, 9, 17, 28, 42, 9, 6, 39]
    (1...30).to_a.sample 10
  end

  def url
    api_comment_url(object)
  end

  def first_name
    object.author.first_name
  end

  def last_name
    object.author.last_name
  end

end
