class Invite < ActiveRecord::Base

  attr_accessor :suppress_invite_email
  attr_accessible :sender_user_id, :first_name, :last_name, :email, :text, :conversation_id, :suppress_invite_email

  validate :invite_code_is_unique, on: :create

  validate :sender_has_not_invited_invitee_already
  validate :no_invite_sent_in_last_12_hours
  validate :invitee_is_not_a_member

  after_create :send_invite_email, unless: Proc.new { |invite| invite.suppress_invite_email }

  has_one :sender, class_name: 'User', foreign_key: :id, primary_key: :sender_user_id
  belongs_to :conversation

  def sender_has_not_invited_invitee_already
    if Invite.exists?(email: self.email, sender_user_id: self.sender_user_id, conversation_id: self.conversation_id )
      self.errors[:base] << "You have already invited this user"
    end
  end

  def no_invite_sent_in_last_12_hours
    if Invite.exists?(email: self.email, created_at: (Time.now - 12.hours)..Time.now, conversation_id: self.conversation_id )
      self.errors[:base] << "This person has been invited recently or is already a participant"
    end
  end

  def invitee_is_not_a_member
    if User.find_by(email: self.email).try{|user| user.roles.exists?(resource_id: self.conversation_id, resource_type: 'Conversation')}
      self.errors[:base] << "This person has been invited recently or is already a participant"
    end
  end


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
    # do not send multiple invites from the same sender
    # do not send multiple invites per day
    ConversationMailer.delay.send_invite(self.sender, self.first_name, self.last_name, self.email, self.text, self.conversation, self.code )
  end

  def confirm_and_create_user params
    conversation = Conversation.find(self.conversation_id)

    params[:user][:password_confirmation] = params[:user][:password]

    user = User.new params[:user]
    user.skip_confirmation!
    user.save

    if user.errors.empty?

      role = assign_role user, conversation

      LogInvite.log invite, user, {assigned_role: role}

      # destroy this invite now that is has been used
      self.destroy
    end
    [user,conversation]
  end

  def assign_role user, conversation
    # default role is
    role = conversation.privacy['screen'] == "true" ? :probationary_participant : :participant
    # check the options to see if the user has been granted higer privileges

    # add role according to invite/conversation setup
    user.add_role role, conversation
    role
  end

end
