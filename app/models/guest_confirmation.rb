class GuestConfirmation < ActiveRecord::Base

  attr_accessible :email, :first_name, :last_name, :code, :conversation_id

  validate :no_email_sent_in_last_20_hours
  before_create :guest_code_is_unique
  after_create :send_guest_confirmation_email

  belongs_to :conversation

  def no_email_sent_in_last_20_hours
    if GuestConfirmation.exists?(email: self.email, created_at: (Time.now - 20.hours)..Time.now)
      self.errors[:base] << "Confirmation email sent within last 20 hours, do not send new email"
    end
  end

  def guest_code_is_unique
    self.code = GuestConfirmation.create_random_guest_code
    while( GuestConfirmation.exists?(code: self.code) ) do
      self.code = GuestConfirmation.create_random_guest_code
    end
  end

  def self.create_random_guest_code
    # I want each invite to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...20).map{ o[rand(o.length)] }.join
  end

  def send_guest_confirmation_email
    ConversationMailer.delay.send_guest_confirmation(self.first_name, self.last_name, self.email, self.code )
  end

  def confirm_and_create_user params
    conversation = Conversation.find(self.conversation_id)

    params[:user][:password_confirmation] = params[:user][:password]
    user = transaction = nil
    transaction do
      user = User.new params[:user]
      user.skip_confirmation!
      user.save

      if user.errors.empty?
        missing_radio = claim_posts_and_invites user, params
        # if any errors, add them to users object and return to the form
        if missing_radio
          Rails.logger.debug "Add missing radio error to user"
          user.errors[:base] << "You must select Mine/Not mine or Accept/Decline for each of the entries below"
          raise ActiveRecord::Rollback
        end
      end

      if user.errors.empty?
        #role = assign_role user, conversation

        LogGuestConfirmation.log self, user, {confirmed: "success"}

        # destroy this guest_confirmation now that is has been used
        self.destroy
      end
    end
    [user,conversation]
  end

  def claim_posts_and_invites user, params
    # check that I have a radio selection for each guest post and conversation invite
    # update the user_id on the guest_posts
    # and create roles for accepted conversation invites

    missing_radio = false
    params.each_pair do |key, value|
      if key.match(/post_\d+/)
        radio_value = params[value]
        if radio_value == 'mine'
          own_post(key, user, 'mine')
        elsif radio_value == 'not_mine'
          own_post(key, user, 'not_mine')
        else
          missing_radio = true
        end

      elsif key.match(/invite_\d+/)
        radio_value = params[value]
        invite_id = key.match(/\d+/)[0].to_i
        if radio_value == 'accept'
          accept_invite(invite_id, user)
        elsif radio_value == 'decline'
          decline_invite(invite_id, user)
        else
          missing_radio = true
        end
      end
    end
    missing_radio
  end

  def accept_invite(invite_id, user)
    Rails.logger.debug "Set role for invite id #{invite_id}"
    invite = Invite.find(invite_id)
    #create the role
    assign_role user, Conversation.find(invite.conversation_id)
    # log the invite
    LogInvite.log invite, user, {invite_claimed_in: 'GuestConfirmation.confirm'}
    # destroy the invite
    invite.destroy
  end

  def decline_invite(invite_id,user)
    Rails.logger.debug "Decline invite id #{invite_id}"
    invite = Invite.find(invite_id)
    LogInvite.log invite, user, {invite_declined_in: 'GuestConfirmation.confirm'}
    # destroy the invite
    invite.destroy
  end

  def assign_role user, conversation
    # default role is
    role = conversation.privacy['screen'] == "true" ? :probationary_participant : :participant
    # check the options to see if the user has been granted higer privileges

    # add role according to invite/conversation setup
    user.add_role role, conversation
    role
  end

  def own_post(key, user, status)
    post_source = key.match(/log_/) ? LogGuestPost : GuestPost
    post_id = key.match(/\d+/)[0].to_i

    if status == 'mine'
      Rails.logger.debug "Set post id #{post_id} to mine in #{post_source}"
      post = post_source.find(post_id)
      Rails.logger.debug "post: #{post.inspect}"
      if post.respond_to?(:comment_id)
        comment = Comment.find(post.comment_id)
        comment.update_column(:user_id, user.id)
      else
        post.update_column(:user_id, user.id)
      end
    else
      Rails.logger.debug "Set post id #{post_id} to not mine in #{post_source}"
      post = post_source.find(post_id)
      if post.respond_to?(:comment_id)
        # don't have to do anything
        # the guest post has been approved as a comment, just leave it unclaimed as Unconfirmed User
      else
        # still a guest post, destroy it
        post.destroy
      end
      Rails.logger.debug "post: #{post.inspect}"
    end
  end

  def guest_posts
    guest_posts = GuestPost.where(email: self.email) +
        LogGuestPost.where(email: self.email)
  end

  def invites
    invites = Invite.where(email: self.email).to_a
    # weed out duplicates
    invites.uniq{|i| i.email && i.conversation_id}
  end


end
