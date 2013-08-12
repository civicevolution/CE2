class HomeController < ApplicationController
  skip_authorization_check :only => [:app]
  def index
    @users = User.all
  end

  def app
    render text: 'ok', layout: 'angular-application'
  end

  def home
    # show the home page
    render layout: false
  end


  def follow

    if params[:email].match(/\@.*\./)
      FollowCe.create email: params[:email]
      AdminMailer.follow_us(params[:email]).deliver
      render template: 'home/follow', layout: false
    else
      render template: 'home/follow-bad-email', layout: false
    end
  end


end
