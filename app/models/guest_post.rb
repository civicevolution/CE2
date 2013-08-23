class GuestPost < ActiveRecord::Base

  attr_accessor :member_status, :code, :accept_join, :invited_at

  attr_accessible :post_type, :user_id, :first_name, :last_name, :email, :conversation_id, :text,
                  :purpose, :reply_to_id, :reply_to_version, :request_to_join

  before_validation :set_user_info_if_user_id_present

  validate :email_is_not_already_registered, unless: Proc.new { |c| c.user_id }
  validates :email, presence: { message: "Must provide email address"}, unless: Proc.new { |c| c.user_id }
  validates :first_name, presence: { message: "Must provide first name"}, unless: Proc.new { |c| c.user_id }
  validates :last_name, presence: { message: "Must provide last name"}, unless: Proc.new { |c| c.user_id }

  #belongs_to :author, ->{ select :id, :first_name, :last_name, :name}, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :conversation

  after_create :send_guest_confirmation_email

  def send_guest_confirmation_email
    # creates a record and sends an email with a code to the record
    GuestConfirmation.create email: self.email, first_name: self.first_name, last_name: self.last_name,
                             conversation_id: self.conversation_id
  end

  def set_user_info_if_user_id_present
    if self.user_id
      user = User.find(self.user_id)
      self.email = user.email
      self.first_name = user.first_name
      self.last_name = user.last_name
    end
  end

  def email_is_not_already_registered
    if User.exists?(email: self.email.downcase)
      self.errors[:email] << 'Email is already registered, Please sign in'
    end
  end

  def accept(conversation_admin)
    # Create a new guest post log record
    # is user confirmed yet
    # Create a new comment based on the guest post
    # add user_id, comment_id to log
    # If user is a confirmed member
    # Make user a participant - at what level? whatever they selected for new users
    # If user is not a confirmed member, create an invite for this user
    # Notify author via email
    # Delete guest_posts record
    Rails.logger.debug "Accept this guest post: #{self.inspect}"

    log = new_log_record
    Rails.logger.debug "log record: #{log.inspect}"

    author = find_post_author_or_use_default # returns author or the default user

    log.user_id = author.id unless log.user_id

    comment = ConversationComment.create user_id: author.id, conversation_id: self.conversation_id, text: self.text,
                                         version: 1, purpose: self.purpose, published: true, status: 'approved'

    log.comment_id = comment.id
    review_details = { comment_action: 'accepted'}

    join_request = ''
    # check/create role if the member requested to join the
    if accept_join == "true"
      join_request = review_details[:join_request] = 'accepted'
      # if the user is confirmed make them a conversation participant, otherwise record an invite for the user
      if !author.confirmed_at.nil?
        role_name = if self.conversation.privacy["screen"] == "true" then 'probationary_participant' else 'participant' end
        author.add_role role_name, self.conversation
      else
        Rails.logger.debug "XXXXXXXXXXX Record an invite for this author, but don't send an email to unconfirmed user"

        invite = Invite.create(sender_user_id: conversation_admin.id,
                               first_name: self.first_name,
                               last_name: self.last_name,
                               email: self.email,
                               conversation_id: self.conversation.id,
                               suppress_invite_email: true
        )
      end
    elsif accept_join == "false"
      join_request = review_details[:join_request] = 'declined'
    end

    log.review_details = review_details
    log.save
    self.destroy

    # send email notification to the author if they are confirmed
    if !author.confirmed_at.nil?
      ConversationMailer.delay.guest_post_accepted(author, self.conversation, comment, join_request)
    end
  end


  def decline(conversation_admin)
    # Create a new guest post log record
    # is user confirmed yet
    # If user is a confirmed member
    # Make user a participant - at what level? whatever they selected for new users
    # If user is not a confirmed member, create an invite for this user
    # Notify author via email
    # Delete guest_posts record
    Rails.logger.debug "Decline this guest post: #{self.inspect}"

    log = new_log_record
    Rails.logger.debug "log record: #{log.inspect}"

    author = find_post_author_or_use_default # returns author or the default user

    log.user_id = author.id unless log.user_id

    review_details = { comment_action: 'declined'}

    join_request = ''
    # check/create role if the member requested to join the
    if accept_join == "true"
      join_request = review_details[:join_request] = 'accepted'
      # if the user is confirmed make them a conversation participant, otherwise record an invite for the user
      if !author.confirmed_at.nil?
        role_name = if self.conversation.privacy["screen"] == "true" then 'probationary_participant' else 'participant' end
        author.add_role role_name, self.conversation
      else
        Rails.logger.debug "XXXXXXXXXXX Record an invite for this author, but don't send an email to unconfirmed user"

        invite = Invite.create(sender_user_id: conversation_admin.id,
                               first_name: self.first_name,
                               last_name: self.last_name,
                               email: self.email,
                               conversation_id: self.conversation.id,
                               suppress_invite_email: true
        )
      end
    elsif accept_join == "false"
      join_request = review_details[:join_request] = 'declined'
    end

    log.review_details = review_details
    log.save
    self.destroy

    # send email notification to the author if they are confirmed
    if !author.confirmed_at.nil?
      ConversationMailer.delay.guest_post_declined(author, self.conversation, log, join_request)
    end
  end

  def new_log_record
    log = LogGuestPost.new
    attributes.each_pair do |key,value|
      case key
        when "id", "updated_at"
        when "created_at"
          log.posted_at = value
        else
          log[key] = value
      end
    end
    log
  end

  def find_post_author_or_use_default
    if self.user_id
      user = User.find( self.user_id)
    else
      user = User.find_by(email: self.email)
    end
    if user.nil? || user.confirmed_at.nil?
      # use the default user if necessary
      user = User.find_by(email: 'unconfirmed-user@civicevolution.org')
    end
    user
  end

end
