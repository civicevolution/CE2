class AttachmentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :attachment_file_name, :attachment_content_type, :attachment_file_size, :url, :icon_url

  def url
    object.attachment.url
  end

  def icon_url
    object.attachment.url(:icon)
  end

end
