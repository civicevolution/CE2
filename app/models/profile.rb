class Profile < ActiveRecord::Base

  attr_protected :user_id, :photo, :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at

  belongs_to :user

  #  validates_attachment_size :photo, :less_than => 2.megabytes if :resource_type == 'upload'
  has_attached_file :photo,
                    :hash_secret => "d7eeKHWw8ppW",
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
                    :path => "users/:res_base/:hash/:style/p.jpg",
                    :url => "http://assets.civicevolution.org/users/:res_base/:hash/:style/p.jpg",
                    :default_url => "/assets/default-user-:style.gif",
                    :bucket => 'assets.civicevolution.org',
                    :styles => {
                        sm1: '36x36',
                        sm2: '50x50',
                        sm3: '60x60',
                        sm4: '75x75',
                        med: '250x250>'
                    }

  #before_post_process :is_this_file_an_image?
  #
  #def is_this_file_an_image?
  #  !(photo_content_type =~ /^image.*/).nil?
  #end


end
