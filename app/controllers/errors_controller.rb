class ErrorsController < ApplicationController
  skip_authorization_check :only => [:show]


  def show
    @exception = env["action_dispatch.exception"]
    status_code = 500
    error_message = @exception.message
    case @exception.class.to_s
      when "CanCan::AccessDenied"
        if current_user.nil?
          Rails.logger.warn "Detected CanCan::AccessDenied - report to requesting agent"
          error_message = "You must be signed in to access this page"
          status_code = 401
        else
          Rails.logger.warn "Detected CanCan::AccessDenied - report to requesting agent"
          status_code = 403
        end
      when "CanCan::AuthorizationNotPerformed"
        Rails.logger.warn "Detected CanCan::AuthorizationNotPerformed - report to requesting agent"
        status_code = 500
      when "ActiveRecord::RecordNotFound"
        Rails.logger.warn "Detected ActiveRecord::RecordNotFound - report to requesting agent"
        status_code = 404
        ## handles 404 when a record is not found.
        #def rescue_action_in_public(exception)
        #  case exception
        #    when ActiveRecord::RecordNotFound, ActionController::UnknownAction, ActionController::RoutingError
        #      render :file => "#{Rails.root}/public/404.html", :layout => 'layouts/application', :status => 404
        #    else
        #      super
        #  end
        #end

      else
        notify_airbrake(@exception) unless Rails.env == 'development' || @exception.message.match(/^CivicEvolution::/)
        Rails.logger.error "\n\nError detected and reported to airbrake:\n #{@exception.class.to_s}: #{@exception.message}"
        @exception.backtrace[0..250].each_index do |ind|
          line = @exception.backtrace[ind]
          if ind < 5
            Rails.logger.error "    #{ind}: #{line}" if ind <6
          elsif line.match(/\/bin\/rails/)
            break
          elsif !line.match(/\/gems\//)
            Rails.logger.error "    #{ind}: #{line}" unless line.match(/\Ascript/)
          end
        end
        Rails.logger.error "    ...\n\n"
    end


    begin
      if params[:format].try{ |format| format.match(/\.json/)}
        request.format = "json"
      end

      if self.env['REQUEST_URI'].match(/\.json/)
        request.format = "json"
      end
    rescue
    end

    respond_to do |format|
      format.html { render action: request.path[1..-1] }
      format.json { render json: {status: status_code, class: @exception.class.to_s, error: error_message,
        controller: params[:controller], action: params[:action]}, status: status_code }
    end
  end
end
