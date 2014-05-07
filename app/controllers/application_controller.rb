class ApplicationController < ActionController::Base
  #protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  #acts_as_token_authentication_handler_for User
  #check_authorization :unless => :devise_controller?
  before_filter :update_sanitized_params, if: :devise_controller?
  after_filter :update_auth_token

  before_filter :cors_preflight_check

  skip_before_filter :verify_authenticity_token, if: :json_request?


  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) {|u| u.permit(:first_name, :last_name, :email, :password, :password_confirmation)}
  end

  def not_found
    #raise ActionController::RoutingError.new('Not Found')
    raise ActiveRecord::RecordNotFound
  end


  private

  def update_auth_token
    headers['X-AUTH-TOKEN'] = current_user.authentication_token unless current_user.nil?
  end

  def cors_preflight_check
    if request.method.to_s.downcase == "options"
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, X-CSRF-TOKEN, Content-Type'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

end
