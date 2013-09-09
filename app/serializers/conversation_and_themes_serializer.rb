class ConversationAndThemesSerializer < ActiveModel::Serializer
  attributes :code, :title, :munged_title, :theme_comments


  def title
    TitleComment.find_by(conversation_id: object.id).try{ |title_comment| title_comment.text} || 'Untitled'
  end

  def munged_title
    title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]
  end

  def themes
    object.theme_comments
  end

end
