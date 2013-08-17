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

        (auth_type, published, status) = conversation.auth_comment(params[:type], params[:comment][:text])
        authorize! auth_type, conversation

        params[:comment][:user_id] = current_user.try{|cu| cu.id}
        params[:comment][:conversation_code] = conversation.code
        params[:comment][:published] = published
        params[:comment][:status] = status
        params[:comment][:auth_type] = auth_type

        case params[:type]
          when "ConversationComment"
            comment = conversation.conversation_comments.create params[:comment]
            if auth_type == :post_unknown && comment.errors.size == 1
              #Rails.logger.debug "Save this comment as a guest_comment"
              guest_post = GuestPost.new  post_type: params[:type],
                                          user_id: params[:comment][:user_id],
                                          first_name: params[:first_name],
                                          last_name: params[:last_name],
                                          email: params[:email],
                                          conversation_id: Conversation.find_by(code: params[:conversation_code]).id,
                                          text: params[:text],
                                          purpose: params[:purpose],
                                          reply_to_id: params[:in_reply_to_id],
                                          reply_to_version: params[:in_reply_to_version],
                                          request_to_join: params[:join]

              #Rails.logger.debug guest_post.inspect
              guest_post.save
              respond_with guest_post
              return
            else
              comment.errors.delete(:auth_type)

            end
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

        (auth_type, published, status ) = conversation.auth_comment(params[:type], params[:comment][:text])
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

      def accept
        Rails.logger.debug "Accept the guest post with params: #{params.inspect}"
        comment = Comment.find(params[:id])
        authorize! :approve_posts, comment.conversation
        comment.accept

        render json: 'ok'
      end

      def decline
        Rails.logger.debug "Decline the guest post with params: #{params.inspect}"
        comment = Comment.find(params[:id])
        authorize! :approve_posts, comment.conversation
        comment.decline

        render json: 'ok'
      end

    end

  end
end
