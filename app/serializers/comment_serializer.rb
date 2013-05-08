class CommentSerializer < ActiveModel::Serializer
  attributes :type, :id, :order_id, :text, :url, :first_name, :last_name

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
