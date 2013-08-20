class InvitesController < ApplicationController
  skip_authorization_check :only => [:lookup, :confirmed]


  def lookup
    if current_user
      # kill off any existing session before creating a new user
      sign_out current_user
    end

    # lookup the :invite_code
    invite = Invite.find_by(code: params[:invite_code])
    if invite.nil?
      render template: 'invites/not-found', layout: 'application'
    elsif User.exists?(email: invite.email)
      render template: 'invites/email-in-use', locals: {email: invite.email}, layout: 'application'
    else
      user = User.new first_name: invite.first_name, last_name: invite.last_name, email: invite.email

      render template: 'invites/confirm', locals: {user: user, code: params[:invite_code]}, layout: 'application'
    end
  end

  def confirmed
    Rails.logger.debug "Guest is confirmed, create an account"

    # make sure the email and the code still match

    invite = Invite.find_by(email: params[:user][:email], code: params[:invite_code])
    if invite.nil?
      render template: 'invites/code-email-dont-match', layout: 'application'
    else
      (user, conversation) = invite.confirm_and_create_user params
      if user.errors.empty?
        sign_in user
        # redirect to the conversation
        redirect_to "/#/conversation/#{conversation.code}/#{conversation.munged_title}"
      else
        # show the form with the errors
        render template: 'invites/confirm', locals: {user: user, code: params[:invite_code]}, layout: 'application'
      end

    end

  end


end
