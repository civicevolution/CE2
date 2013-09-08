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
        test_id = Rails.env == "development" ? 13 : 7
        conversations = Conversation.where(id: test_id)
        respond_with conversations, each_serializer: ConversationSerializer
      end
    end
  end
end