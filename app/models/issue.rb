class Issue < ActiveRecord::Base
  attr_accessible :description, :intiative_id, :purpose, :status, :title, :user_id, :version

  belongs_to :initiative
  belongs_to :user

  has_many :questions

  has_many :attachments, :as => :attachable

  validates :initiative_id, :user_id, :title, :description, :version, :status, :purpose, presence: true

  before_create :calculate_munged_title

  def calculate_munged_title
    self.munged_title = to_param
  end

  def to_param
    title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase
  end

end
