module Api
  module V1

    class RealtimeAuthorizeController < Api::BaseController
      skip_authorization_check :only => [:authorize_realtime_channel]

      def authorize_realtime_channel
        channel = params[:channel]
        #Rails.logger.debug "authorize_realtime_channel: #{channel}"
        Modules::FayeRedis::add_session_to_redis(request.session_options[:id], current_user, [channel], [])
        render json: 'approved'
      end

    end
  end
end