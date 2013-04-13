class CommentSerializer < ActiveModel::Serializer
  attributes :id, :name, :text, :liked, :url

  def url
    api_comment_url(object)
  end
  
  
end
