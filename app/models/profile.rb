class Profile < ActiveRecord::Base

  attr_protected :user_id, :photo, :photo_file_name, :photo_content_type, :photo_file_size, :photo_updated_at

  belongs_to :user

  #  validates_attachment_size :photo, :less_than => 2.megabytes if :resource_type == 'upload'
  has_attached_file :photo,
                    #:hash_secret => "d7eeKHWw8ppW",
                    #:hash_data => ":class/:attachment/:id:updated_at",
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
                    :path => "users/:res_base/:user_code/:style/p.jpg",
                    :url => "http://assets.civicevolution.org/users/:res_base/:user_code/:style/p.jpg",
                    :default_url => "http://assets.civicevolution.org/users/:res_base/default-user/:style/p.gif",
                    :bucket => 'assets.civicevolution.org',
                    :styles => {
                        sm1: '20x20',
                        sm2: '28x28',
                        sm3: '36x36',
                        sm4: '50x50',
                        sm5: '60x60',
                        med: '250x250>'
                    }

  #before_post_process :is_this_file_an_image?
  #
  #def is_this_file_an_image?
  #  !(photo_content_type =~ /^image.*/).nil?
  #end


end
