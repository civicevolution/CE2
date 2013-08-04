module Api
  module V1

    class CommentsController < Api::BaseController
      load_and_authorize_resource
      
      def index
        if params[:ids]
          respond_with Comment.includes(:author).where(id: params[:ids].scan(/\d+/) )
        else
          respond_with Comment.includes(:author).all
        end

        #Conversation.first.summary_comments(:includes=> :author)
      end

      def show
        respond_with Comment.find(params[:id])
        #render :json => Comment.find(params[:id]), :serializer => CommentSerializer
      end

      def create
        Rails.logger.debug "Create the comment with params: #{params.inspect}"
        conversation = Conversation.find_by(code: params[:conversation_code])

        authorize! :create, conversation

        params[:comment][:user_id] = current_user.id
        params[:comment][:conversation_code] = conversation.code
        case params[:type]
          when "ConversationComment"
            comment = conversation.conversation_comments.create params[:comment]
          when "SummaryComment"
            comment = conversation.summary_comments.create params[:comment]
          when "CallToActionComment"
            comment = conversation.create_call_to_action_comment params[:comment]
          when "TitleComment"
            comment = conversation.create_title_comment params[:comment]
        end

        respond_with comment
      end

      def update
        logger.debug "update the comment with id: #{params[:id]}"
        comment = Comment.find(params[:id])
        conversation = comment.conversation
        comment.conversation_code = conversation.code
        comment.update(params[:comment])
        respond_with comment
        #respond_with Comment.update(params[:id], params[:comment])
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
