module Api
  module V1

    class NotificationRequestsController < Api::BaseController
      #load_and_authorize_resource

      def create
        Rails.logger.debug "NotificationRequestsController.create params: #{params.inspect}"
        conversation = Conversation.find_by(code: params[:conversation_code])
        request = NotificationRequest.where(conversation_id: conversation.id, user_id: current_user.id).first_or_create
        request.update_request params[:settings]

        render json: 'ok'
      end

    end

  end
end
