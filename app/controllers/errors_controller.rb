class ErrorsController < ApplicationController
  skip_authorization_check :only => [:show]


  def show
    @exception = env["action_dispatch.exception"]

    case @exception.class.to_s
      when "CanCan::AccessDenied"
        Rails.logger.warn "Detected CanCan::AccessDenied - report to requesting agent"
      when "CanCan::AuthorizationNotPerformed"
        Rails.logger.warn "Detected CanCan::AuthorizationNotPerformed - report to requesting agent"
      when "ActiveRecord::RecordNotFound"
        Rails.logger.warn "Detected ActiveRecord::RecordNotFound - report to requesting agent"
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
        Rails.logger.debug "XXXXXXXXXX\nXXXXXXXX\nXXXXXXXX\nRe-enable Airbrake\nXXXXXXXXXX\nXXXXXXXX\nXXXXXXXX\n"
        #notify_airbrake(@exception) unless Rails.env == 'development' || @exception.message.match(/^CivicEvolution::/)
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
      format.json { render json: {status: request.path[1..-1], class: @exception.class.to_s, error: @exception.message,
        controller: params[:controller], action: params[:action]}, status: request.path[1..-1] }
    end
  end
end
