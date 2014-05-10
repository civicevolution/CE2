module Api
  class BaseController < ApplicationController
    check_authorization :unless => :devise_controller?

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