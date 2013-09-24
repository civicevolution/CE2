class ConversationListAllSerializer < ActiveModel::Serializer
  attributes :code, :title, :munged_title


  def title
    object.title || 'Untitled'
  end

  def munged_title
    title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]
  end

end
