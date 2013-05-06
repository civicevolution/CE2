class Initiative < ActiveRecord::Base
  attr_accessible :description, :title

  has_many :issues

  validates :title, :description, :presence => true

end
