module Api
  module V1

    class CommentsController < Api::BaseController

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

        (auth_type, published, status) = auth_comment(conversation, params[:comment][:text])
        authorize! auth_type, conversation

        params[:comment][:user_id] = current_user.try{|cu| cu.id}
        params[:comment][:conversation_code] = conversation.code
        params[:comment][:published] = published
        params[:comment][:status] = status

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

        (auth_type, published, status ) = auth_comment(conversation, params[:comment][:text])
        authorize! auth_type, conversation

        params[:comment][:conversation_code] = conversation.code
        params[:comment][:published] = published
        params[:comment][:status] = status

        comment.update(params[:comment])
        respond_with comment
      end

      def destroy
        respond_with Comment.destroy(params[:id])
      end

      def history
        comment = Comment.find(params[:id])
        authorize! :history, comment.conversation
        respond_with comment.history_diffs
        logger.debug "Show the history"
      end

      def rate
        @comment = Comment.find(params[:comment_id])
        authorize! :rate_comment, @comment.conversation
        rating = @comment.ratings.where(user_id: current_user.id).first_or_initialize
        rating.rating = params[:rating]
        rating.save
        respond_with Comment.find(params[:comment_id]).ratings_cache
      end

      private

      def auth_comment( conversation, text )
        case params[:type]
          when "ConversationComment"
            # should this comment be published automatically, or does it need to be reviewed by curator?
            case
              when can?(:post_any, conversation)
                auth_type = :post_any
                published = true
                status = 'new'
              when can?(:post_no_attachments, conversation)
                auth_type = :post_no_attachments
                # check content of text for image/link/attachment
                if text.match(/http/) || text.match(/<img/)
                  published = false
                  status = 'pre-review'
                else
                  published = true
                  status = 'new'
                end
              when can?(:post_prescreen, conversation)
                auth_type = :post_prescreen
                published = false
                status = 'pre-review'
            end
          when "SummaryComment"
            auth_type = :edit_summary
            published = true
            status = 'ok'
          when "CallToActionComment"
            auth_type = :edit_cta
            published = true
            status = 'ok'
          when "TitleComment"
            auth_type = :edit_title
            published = true
            status = 'ok'
        end
        [auth_type, published, status]
      end

    end

  end
end
