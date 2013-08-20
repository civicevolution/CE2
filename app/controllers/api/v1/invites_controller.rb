module Api
  module V1

    class InvitesController < Api::BaseController

      def create
        Rails.logger.debug "Create the invite with params: #{params.inspect}"

        conversation = Conversation.find_by(code: params[:id])
        authorize! :invite, conversation

        invite = Invite.create(sender_user_id: current_user.id,
                               first_name: params[:first_name],
                               last_name: params[:last_name],
                               email: params[:email],
                               text: params[:message],
                               conversation_id: conversation.id
                              )
        # options from curator trusted | curator

        respond_with invite, serializer: InvitedGuestSerializer

      end


    end

  end
end
