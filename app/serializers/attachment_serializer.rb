class AttachmentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :attachment_file_name, :attachment_content_type, :attachment_file_size, :url, :icon_url, :small_url, :medium_url

  def url
    object.attachment.url
  end

  def icon_url
    case
      when object.attachment_content_type.match(/image.*/i)
        object.attachment(:icon)
      else
        '/assets/doc_icon.gif'
    end
  end

  def small_url
    case
      when object.attachment_content_type.match(/image.*/i)
        object.attachment(:small)
      else
        '/assets/doc_icon.gif'
    end
  end

  def medium_url
    case
      when object.attachment_content_type.match(/image.*/i)
        object.attachment(:medium)
      else
        '/assets/doc_icon.gif'
    end
  end

end
