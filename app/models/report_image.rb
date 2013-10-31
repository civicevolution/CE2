class ReportImage < ActiveRecord::Base

  attr_accessible :image, :image_file_name, :image_content_type, :image_file_size, :image_updated_at

  belongs_to :report


  has_attached_file :image,
                    :hash_secret => "c1hkKH78WppW",
                    :hash_data => ":class/:attachment/:id:updated_at",
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root}/config/s3.yml",
                    :path => "reports/:res_base/:hash/:style/:basename.:extension",
                    :url => "http://assets.civicevolution.org/reports/:res_base/:hash/:style/:basename.:extension",
                    :bucket => 'assets.civicevolution.org',
                    :styles => {
                        icon: '50x50>',
                    }

end
