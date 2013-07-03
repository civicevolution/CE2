class HomeController < ApplicationController
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

end
