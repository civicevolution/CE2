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
                    :styles => { :icon => '50x50>' }

  def icon_url
    case
      when self.attachment_content_type.match(/image/i)
        self.attachment(:icon)
      else
        '/assets/doc_icon.gif'
    end
  end


  before_post_process :image?

  private

  def image?
    !(attachment_content_type =~ /^image.*/).nil?
  end


end