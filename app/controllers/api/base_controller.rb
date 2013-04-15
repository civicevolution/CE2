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

    def rescue_generic_exception(e)
      logger.error "\n\nError detected: #{e.class.to_s}: #{e.message}"
      notify_airbrake(e) unless Rails.env == 'development'
      #raise e
      render json: {system_error: e.message}, :status => :internal_server_error
    end
    
    def rescue_not_found(e)
      logger.debug "return something about record not found"
      render json: {system_error: e.message}, :status => :not_found
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