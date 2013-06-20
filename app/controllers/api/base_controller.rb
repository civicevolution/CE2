module Api
  class BaseController < ApplicationController
    protect_from_forgery
    #skip_before_filter :verify_authenticity_token, if: :json_request?
    
    # Use custom responder to return 200 and object on update
    # Automatically returns the errors as JSON
    responders :json
    
    respond_to :json
    
    ###
    #  rescue_from is processed in reverse order as they are listed below
    #  Put the most specific error at the bottom and the most generic at the top
    ###
    rescue_from Exception, with: :rescue_generic_exception
    rescue_from ActiveRecord::RecordNotFound, with: :rescue_not_found
    rescue_from CanCan::AccessDenied, with: :cancan_denied
    # Add additional errors that I can handle

    
    protected

    def json_request?
      request.format.json?
    end

    def default_serializer_options
      {root: false}
    end

    def rescue_generic_exception(exception)
      notify_airbrake(exception) unless Rails.env == 'development'

      exception.backtrace[0..5].each_index do |ind|
        Rails.logger.error "    #{ind}: #{exception.backtrace[ind]}"
      end
      #exception.backtrace[6..250].each do |line|
      #  if !line.match(/\/gems\//)
      #    Rails.logger.error ">>>>#{line}" unless line.match(/\Ascript/)
      #  end
      #end
      Rails.logger.error "\n\n"
      #logger.error "\n\nError detected: #{exception.class.to_s}: #{exception.message}"
      #raise e
      render json: {system_error: exception.message}, :status => :internal_server_error
    end
    
    def rescue_not_found(e)
      msg = "Api::BaseController.rescue_not_found, return something about record not found"
      logger.debug msg
      render json: {system_error: e.message, message: msg}, :status => :not_found
    end
    
    def cancan_denied(e)
      denied_object = params[:controller].match(/\w+$/)[0]
      denied_action = case params[:action]
      when "index" then "view"
      else params[:action]
      end
      msg = "You don't have permission to #{denied_action} #{denied_object}"
      logger.debug msg
      render json: {system_error: msg}, :status => :unauthorized
		end

  end
end  