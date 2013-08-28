class SubscribesController < ApplicationController
  skip_authorization_check :only => [:follow, :unsubscribe]

  def unsubscribe
    log = LogEmail.find_by(token: params[:token])
    if log.nil?
      render template: 'subscribes/un-subscribed-not-found', layout: false
    else
      begin
        Unsubscribe.create email: log.email, subject: log.subject
      rescue ActiveRecord::RecordNotUnique
      end
      log.destroy

      @redacted_email = log.email.sub(/^(\w[^@]*)/){ |name| "#{name[0...1]}#{'*'*(name.size - 1)}"}
      render template: 'subscribes/un-subscribed', layout: false

    end


  end

end
