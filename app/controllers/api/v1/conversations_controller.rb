module Api
  module V1

    class ConversationsController < Api::BaseController
      load_and_authorize_resource
      #def default_serializer_options
      #  {
      #      root: false
      #  }
      #end

      def index
        #respond_with Conversations.comments.where(id: params[:id])
        respond_with Conversations.find(  params[:id])
        #Conversation.first.summary_comments(:includes=> :author)
      end

      def show
        respond_with Conversation.find(params[:id])#, :root => false
      end

      def create
        respond_with ConversationComment.create(params[:comment])
      end

      def update
        respond_with Comment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Comment.destroy(params[:id])
      end

    end

  end
end
