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
        test_ids = Rails.env == "development" ? [18,19,20] : [8,9,10]
        #test_ids = request.subdomain == 'aus' ? [1,2,3] : test_ids
        conversations = Conversation.where(id: test_ids)
        respond_with conversations, each_serializer: ConversationListSerializer
      end

      def conversations_and_themes
        authorize! :list_iap2_conversations, Conversation
        test_ids = Rails.env == "development" ? [18,19,20] : [8,9,10]
        #test_ids = request.subdomain == 'aus' ? [1,2,3] : test_ids
        conversations = Conversation.where(id: test_ids)
        respond_with conversations, each_serializer: ConversationAndThemesSerializer
      end

    end
  end
end