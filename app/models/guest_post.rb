class GuestPost < ActiveRecord::Base

  attr_accessible :post_type, :user_id, :first_name, :last_name, :email, :conversation_id, :text,
                  :purpose, :reply_to_id, :reply_to_version, :request_to_join

  #validates :user_id, :presence => true, unless: Proc.new { |c| c.email || c.first_name || c.last_name }
  validates :email, presence: { message: "Must provide email address"}, unless: Proc.new { |c| c.user_id }
  validates :first_name, presence: { message: "Must provide first name"}, unless: Proc.new { |c| c.user_id }
  validates :last_name, presence: { message: "Must provide last name"}, unless: Proc.new { |c| c.user_id }

end
