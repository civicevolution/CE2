class ContactsController < ApplicationController
  skip_authorization_check :only => [:follow, :send_message]


  def follow

    if params[:email].match(/\@.*\./)
      FollowCe.create email: params[:email]
      render template: 'subscribes/follow', layout: false
    else
      render template: 'subscribes/follow-bad-email', layout: false
    end
  end

  def send_message

    Rails.logger.debug "contacts#send_message"
    if current_user
      params[:message][:user_id] = current_user.id
    end
    contact = Contact.create params[:message]

    render json: contact


  end

end
