class ApplicationController < ActionController::Base
  #protect_from_forgery
  acts_as_token_authentication_handler_for User

  check_authorization :unless => :devise_controller?
  before_filter :update_sanitized_params, if: :devise_controller?
  after_filter :send_auth_token, if: :devise_controller?

  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) {|u| u.permit(:first_name, :last_name, :email, :password, :password_confirmation)}
  end

  def not_found
    #raise ActionController::RoutingError.new('Not Found')
    raise ActiveRecord::RecordNotFound
  end


  private

  def send_auth_token
    headers['X-User-Token'] = current_user.authentication_token unless current_user.nil?
  end

end
