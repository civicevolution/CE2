class Attachment < ActiveRecord::Base

  attr_accessible :attachment, :attachable_id, :attachable_type, :user_id, :title, :description, :version, :status, :attachment_file_name, :attachment_content_type, :attachment_file_size, :attachment_updated_at

  belongs_to :attachable, :polymorphic => true

  has_attached_file :attachment,
                    :hash_secret => "c1hkKH78WppW",
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root}/config/s3.yml",
                    :path => "upload/:res_base/:hash/:basename.:extension",
                    :url => "http://assets.civicevolution.org/upload/:res_base/:hash/:basename.:extension",
                    :bucket => 'assets.civicevolution.org',
                    :styles => {
                      icon: '50x50>',
                      small: '200x200>',
                      medium: '400x400>'

  }

  before_post_process :cancel_post_process_if_not_image?


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