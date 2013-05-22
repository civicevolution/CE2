module Api
  module V1

    class CommentsController < Api::BaseController
      load_and_authorize_resource
      
      def index
        respond_with Comment.includes(:author).all
        #Conversation.first.summary_comments(:includes=> :author)
      end

      def show
        respond_with Comment.find(params[:id])
        #render :json => Comment.find(params[:id]), :serializer => CommentSerializer
      end

      def create
        params[:comment][:user_id] = current_user.id
        params[:comment][:conversation_id] = 1
        respond_with ConversationComment.create(params[:comment])
      end

      def update
        logger.debug "update the comment with id: #{params[:id]}"
        respond_with Comment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Comment.destroy(params[:id])
      end

      def history
        respond_with @comment.history_diffs
        logger.debug "Show the history"
      end

      def rate
        @comment = Comment.find(params[:comment_id])
        rating = @comment.ratings.where(user_id: current_user.id).first_or_initialize
        rating.rating = params[:rating]
        rating.save
        respond_with Comment.find(params[:comment_id]).ratings_cache
      end

    end

  end
end
