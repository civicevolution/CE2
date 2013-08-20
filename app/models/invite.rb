class Invite < ActiveRecord::Base

  attr_accessible :sender_user_id, :first_name, :last_name, :email, :text, :conversation_id

  validate :invite_code_is_unique, on: :create
  after_create :send_invite_email

  has_one :sender, class_name: 'User', foreign_key: :id, primary_key: :sender_user_id
  belongs_to :conversation


  def invite_code_is_unique
    self.code = Invite.create_random_invite_code
    while( Invite.where(code: self.code).exists? ) do
      self.code = Invite.create_random_invite_code
    end
  end

  def self.create_random_invite_code
    # I want each invite to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...20).map{ o[rand(o.length)] }.join
  end

  def send_invite_email
    ConversationMailer.delay.send_invite(self.sender, self.first_name, self.last_name, self.email, self.text, self.conversation, self.code )
  end
end
