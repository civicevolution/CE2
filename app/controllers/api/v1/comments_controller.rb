module Api
  module V1

    class CommentsController < Api::BaseController

      def index
        if params[:ids]
          comments = Comment.includes(:author).where(id: params[:ids].scan(/\d+/) )
          authorize! :show, comments[0].conversation
          respond_with comments
        else
          comment = Comment.includes(:author).all
          authorize! :show, comment.conversation
          respond_with comment
        end
      end

      def show
        comment = Comment.includes(:author).find(params[:id])
        authorize! :show, comment.conversation
        respond_with comment
      end

      def create
        Rails.logger.debug "Create the comment with params: #{params.inspect}"
        conversation = Conversation.find_by(code: params[:conversation_code])

        (auth_type, published, status) = auth_comment(conversation, params[:type], params[:comment][:text])
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
          when "ThemeComment"
            params[:comment][:purpose] ||= 'theme'
            params[:comment][:tag_name] = params[:tag_name]
            params[:comment][:text] ||= "Please write a description for tag: #{params[:comment][:tag_name]}"

            debug_theme = false
            if !debug_theme
              comment = conversation.theme_comments.create params[:comment]
            else
              comment = conversation.theme_comments.last
              comment.tag_name = params[:tag_name] + ' (F)'
              comment.text = "Please write a description for tag: #{params[:tag_name]}"
              comment.id = 1000 + rand(100000)
              comment.created_at = Time.now
              comment.updated_at = Time.now
            end

            Rails.logger.debug "theme comment #{comment.inspect}"
          when "TableComment"
            comment = conversation.table_comment.create params[:comment]
        end

        respond_with comment
      end

      def update
        logger.debug "update the comment with id: #{params[:id]}"
        comment = Comment.find(params[:id])
        conversation = comment.conversation

        (auth_type, published, status ) = auth_comment(conversation, params[:type], params[:comment][:text])
        authorize! auth_type, conversation

        params[:comment][:conversation_code] = conversation.code
        params[:comment][:published] = published
        params[:comment][:status] = status

        comment.update(params[:comment])
        respond_with comment
      end

      def destroy
        comment = Comment.find(params[:id])
        raise "CivicEvolution::CommentDestroyNotAllowed for type:#{comment.type}" unless comment.type == 'ThemeComment'
        # make sure the comment doesn't have any children
        raise "CivicEvolution::CommentDestroyNotAllowed if child comments" if comment.child_targets.size > 0
        authorize! :destroy_theme_comment, comment.conversation
        comment.destroy
        respond_with comment

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

      def assign_themes
        comment = Comment.find(params[:id])
        authorize! :assign_comment_theme, comment.conversation
        if params[:act] == 'add'
          Comment.find(params[:theme_id]).child_comments << comment
        else
          Comment.find(params[:theme_id]).child_comments.delete(comment)
        end
        respond_with comment
      end

      def update_comment_order
        #Rails.logger.debug "api/comments_controller.update_comment_order for comment #{params[:id]}"

        comment = Comment.find(params[:id])
        authorize! :update_comment_order, comment.conversation

        ids_with_order_id = Comment.update_comment_order( params[:id], params[:ordered_ids] )
        #if !ids_with_order_id.empty?
        #  #Firebase.base_uri = "https://civicevolution.firebaseio.com/issues/#{conversation.question.issue_id}/conversations/#{conversation.id}/updates/"
        #  Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{conversation.code}/updates/"
        #  Firebase.push '', { class: 'Conversation', action: 'update_comment_order', data: {conversation_code: params[:id], ordered_ids: ids_with_order_id }, updated_at: Time.now.getutc, source: "RoR-Firebase" }
        #end

        render json: 'ok'
      end


      def auth_comment( conversation, type, text )
        case type
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
              when can?(:post_unknown, conversation)
                auth_type = :post_unknown
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
          when "TableComment"
            auth_type = :edit_table_comment
            published = true
            status = 'ok'
          when "ThemeComment"
            auth_type = :edit_theme_comment
            published = true
            status = 'ok'
        end
        [auth_type, published, status]
      end

    end

  end
end
