class SubscribesController < ApplicationController
  skip_authorization_check :only => [:follow, :unsubscribe]


  def follow

    if params[:email].match(/\@.*\./)
      FollowCe.create email: params[:email]
      AdminMailer.follow_us(params[:email]).deliver
      render template: 'subscribes/follow', layout: false
    else
      render template: 'subscribes/follow-bad-email', layout: false
    end
  end

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
