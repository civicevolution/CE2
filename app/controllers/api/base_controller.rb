module Api
  class BaseController < ApplicationController
    #check_authorization :unless => :devise_controller?
    #skip_before_filter :verify_authenticity_token, if: :json_request?
    skip_before_filter :verify_authenticity_token

    before_filter :cors_preflight_check

    def cors_preflight_check
      if request.method.to_s.downcase == "options"
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
        headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, X-CSRF-TOKEN, Content-Type'
        headers['Access-Control-Max-Age'] = '1728000'
        render :text => '', :content_type => 'text/plain'
      end
    end

    # Use custom responder to return 200 and object on update
    # Automatically returns the errors as JSON
    responders :json
    
    respond_to :json

    protected

    def json_request?
      request.format.json?
    end

    def default_serializer_options
      {root: false}
    end

  end
end  