class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :update_sanitized_params, if: :devise_controller?

  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) {|u| u.permit(:first_name, :last_name, :email, :password, :password_confirmation)}
  end

  rescue_from ActiveRecord::RecordNotFound, :with => :rescue_action_in_public

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def not_found
    #raise ActionController::RoutingError.new('Not Found')
    raise ActiveRecord::RecordNotFound
  end

  private

  # handles 404 when a record is not found.
  def rescue_action_in_public(exception)
    case exception
      when ActiveRecord::RecordNotFound, ActionController::UnknownAction, ActionController::RoutingError
        render :file => "#{Rails.root}/public/404.html", :layout => 'layouts/application', :status => 404
      else
        super
    end
  end

end
