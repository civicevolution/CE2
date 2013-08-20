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

  def confirm_and_create_user params
    conversation = Conversation.find(self.conversation_id)

    params[:user][:password_confirmation] = params[:user][:password]

    user = User.new params[:user]
    user.skip_confirmation!
    user.save

    if user.errors.empty?

      role = assign_role user, conversation

      log_invite user, {assigned_role: role}

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

  def log_invite user, details
    log = LogInvite.new
    attributes.each_pair do |key,value|
      case key
        when "id", "updated_at"
        when "created_at"
          log.invited_at = value
        else
          log[key] = value
      end
    end
    log.user_id = user.id
    log.details = details
    log.save

  end

end
