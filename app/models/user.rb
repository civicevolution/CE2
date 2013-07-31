class User < ActiveRecord::Base
  rolify

  has_one :profile
  has_many :notification_requests

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role_ids, :as => :admin
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  attr_accessible :first_name, :last_name

  validates :first_name, :last_name, :presence => true

  after_create :add_participant_role, :add_profile

  before_create :create_unique_name_count

  def create_unique_name_count
    num_similar_names = User.where("lower(first_name) = lower(?) AND lower(last_name) = lower(?)",self.first_name, self.last_name).maximum(:name_count) || 0
    self.name_count = num_similar_names += 1
  end

  def add_participant_role
    add_role :participant
  end

  def add_profile
    self.profile = Profile.create
  end


end
