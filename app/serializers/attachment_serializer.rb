class AttachmentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :attachment_file_name, :attachment_content_type, :attachment_file_size, :url, :icon_url, :in_page_url, :image_height, :image_width

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

  def in_page_url
    case
      when object.attachment_content_type.match(/image.*/i)
        object.attachment(:in_page)
      else
        '/assets/doc_icon.gif'
    end
  end

end
