class Attachment < ActiveRecord::Base

  attr_accessible :attachment, :attachable_id, :attachable_type, :user_id, :title, :description, :version, :status, :attachment_file_name, :attachment_content_type, :attachment_file_size, :attachment_updated_at

  belongs_to :attachable, :polymorphic => true

  has_attached_file :attachment,
                    :hash_secret => "c1hkKH78WppW",
                    :hash_data => ":class/:attachment/:id:updated_at",
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root}/config/s3.yml",
                    :path => "upload/:res_base/:hash/:style/:basename.:extension",
                    :url => "http://assets.civicevolution.org/upload/:res_base/:hash/:style/:basename.:extension",
                    :bucket => 'assets.civicevolution.org',
                    :styles => {
                      icon: '50x50>',
                      in_page: '600x600>'
                    }

  before_post_process :cancel_post_process_if_not_image?
  after_post_process :save_image_dimensions

  def save_image_dimensions
    return if (attachment_content_type.match(/image.*/i)).nil?
    geo = Paperclip::Geometry.from_file(attachment.queued_for_write[:original])
    self.image_width = geo.width
    self.image_height = geo.height
    Rails.logger.debug "saveimage dimensions heigth: #{self.image_height}, width: #{self.image_width}"
  end

  def icon_url
    case
      when attachment_content_type.match(/image.*/i)
        attachment(:icon)
      else
        '/assets/doc_icon.gif'
    end
  end


  private

  def cancel_post_process_if_not_image?
    !(attachment_content_type.match(/image.*/i)).nil?
  end


end