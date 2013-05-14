module Api
  module V1

    class AttachmentsController < Api::BaseController
      load_and_authorize_resource

      def index
        respond_with Attachment.includes(:author).all
        #Conversation.first.summary_comments(:includes=> :author)
      end

      def show
        respond_with Attachment.find(params[:id])
        #render :json => Comment.find(params[:id]), :serializer => CommentSerializer
      end

      def create
        params[:attachment][:user_id] = current_user.id
        params[:attachment][:attachable_id] = 0
        params[:attachment][:attachable_type] = 'Undefined'
        respond_with Attachment.create(params[:attachment])
      end


      def update
        logger.debug "update the comment with id: #{params[:id]}"
        respond_with Attachment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Attachment.destroy(params[:id])
      end

      def history
        respond_with @comment.history_diffs
        logger.debug "Show the history"
      end

    end

  end
end
