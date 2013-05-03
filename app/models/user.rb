class User < ActiveRecord::Base
  rolify
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

  validates :first_name, :presence => true
  validates :last_name, :presence => true

  after_create :add_participant_role
  
  def add_participant_role
    add_role :participant
  end

	
  
end
