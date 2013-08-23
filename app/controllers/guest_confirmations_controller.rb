class GuestConfirmationsController < ApplicationController
  skip_authorization_check :only => [:lookup, :confirmed]


  def lookup
    if current_user
      # kill off any existing session before creating a new user
      sign_out current_user
    end

    # lookup the :guest_confirmation_code
    guest_confirmation = GuestConfirmation.find_by(code: params[:guest_confirmation_code])
    if guest_confirmation.nil?
      render template: 'guest_confirmations/not-found', layout: 'application'
    elsif User.exists?(email: guest_confirmation.email)
      guest_confirmation.destroy
      render template: 'guest_confirmations/email-in-use', locals: {email: guest_confirmation.email}, layout: 'application'
    else
      user = User.new first_name: guest_confirmation.first_name, last_name: guest_confirmation.last_name, email: guest_confirmation.email

      render template: 'guest_confirmations/confirm', locals: {user: user, guest_confirmation: guest_confirmation, code: params[:guest_confirmation_code]}, layout: 'application'
    end
  end

  def confirmed
    Rails.logger.debug "Guest is confirmed, create an account"

    # make sure the email and the code still match

    guest_confirmation = GuestConfirmation.find_by(email: params[:user][:email], code: params[:guest_confirmation_code])
    if guest_confirmation.nil?
      render template: 'guest_confirmations/code-email-dont-match', layout: 'application'
    else
      Rails.logger.debug "GuestConfirmation params: #{params.inspect}"
      (user, conversation) = guest_confirmation.confirm_and_create_user params
      if user.errors.empty?
        sign_in user
        # redirect to the conversation
        redirect_to "/#/conversation/#{conversation.code}/#{conversation.munged_title}"
      else
        # show the form with the errors
        render template: 'guest_confirmations/confirm', locals: {user: user, guest_confirmation: guest_confirmation, code: params[:guest_confirmation_code]}, layout: 'application'
      end

    end

  end


end
