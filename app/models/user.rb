class User < ActiveRecord::Base
  rolify

  has_one :profile
  has_many :notification_requests

  has_many :mentioneds, class_name: 'Mention', foreign_key: :mentioned_user_id
  has_many :mentions, class_name: 'Mention', foreign_key: :user_id


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

  before_create :create_unique_user_code

  def create_unique_user_code
    self.code = User.create_random_user_code
    while( User.where(code: self.code).exists? ) do
      self.code = User.create_random_user_code
    end
  end

  def self.create_random_user_code
    # I want each conversation to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...10).map{ o[rand(o.length)] }.join
  end


  def create_unique_name_count
    num_similar_names = User.where("lower(first_name) = lower(?) AND lower(last_name) = lower(?)",self.first_name, self.last_name).maximum(:name_count) || 0
    self.name_count = num_similar_names += 1
    self.name = "#{self.first_name}_#{self.last_name}"
    if self.name_count > 1
      self.name += "_#{self.name_count}"
    end
  end

  def add_participant_role
    add_role :participant
  end

  def add_profile
    self.profile = Profile.create
  end


end
