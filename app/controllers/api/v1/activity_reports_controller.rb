module Api
  module V1

    class ActivityReportsController < Api::BaseController
      skip_authorization_check :only => [:record]

      def record
        Rails.logger.debug "ActivityReports#record with IP: #{request.remote_ip}"
        begin
          if current_user
            params[:report][:user_id] = current_user.id
          end

          params[:report][:ip_address] = request.remote_ip
          ActivityReport.create params[:report]

        rescue Exception => exception
          # TODO report this error to Airbrake
          notify_airbrake(exception) unless Rails.env == 'development'
        end


        render json: 'ok'
      end
    end
  end
end
