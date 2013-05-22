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
        conversation = Conversation.includes(:comments).find(params[:id])
        my_ratings = Rating.where( user_id: current_user.id, ratable_id: conversation.comments.map(&:id), ratable_type: 'Comment').inject({}){|hash, r| hash[r.ratable_id] = r.rating ; hash }
        conversation.comments.each{|com| com.my_rating = my_ratings[com.id]}
        respond_with conversation
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
