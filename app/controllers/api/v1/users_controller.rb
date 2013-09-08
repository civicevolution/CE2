module Api
  module V1
    class UsersController < Api::BaseController
      skip_authorization_check only: [:user]

      def user
        current_user
        respond_with current_user
      end

      def conversations
        authorize! :list_iap2_conversations, Conversation
        conversations = Conversation.where(id: 13)
        respond_with conversations, each_serializer: ConversationSerializer
      end
    end
  end
end