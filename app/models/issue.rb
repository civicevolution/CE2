class Issue < ActiveRecord::Base
  attr_accessible :description, :intiative_id, :purpose, :status, :title, :user_id, :version

  belongs_to :initiative
  belongs_to :user

  has_many :questions

  validates :initiative_id, :user_id, :title, :description, :version, :status, :purpose, presence: true

end
