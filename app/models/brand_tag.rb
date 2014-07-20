class BrandTag < ActiveRecord::Base
  attr_accessible :user_id, :name

  has_and_belongs_to_many :conversations

end
