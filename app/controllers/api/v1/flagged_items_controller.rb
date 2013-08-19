module Api
  module V1

    class FlaggedItemsController < Api::BaseController

      def index
        #if params[:ids]
        #  respond_with Comment.includes(:author).where(id: params[:ids].scan(/\d+/) )
        #else
        #  respond_with Comment.includes(:author).all
        #end
      end

      def create
        Rails.logger.debug "Flag item with params: #{params.inspect}"
        conversation =
            case params[:type]
              when "Comment"
                Comment.find(params[:id]).conversation
              when "Conversation"
                Conversation.find_by(code: params[:id])
            end
        authorize! :flag, Conversation

        flagged_item = FlaggedItem.create(user_id: current_user.id, conversation_id: conversation.id, target_type: params[:type],
                                          target_id: params[:id], version: params[:version], category: 'SPAM', statement: "Statement @ #{Time.now}")
        respond_with flagged_item

      end


      def mark_flagged_as
        Rails.logger.debug "mark_flagged_as the comment with params: #{params.inspect}"
        item = FlaggedItem.find(params[:id])
        authorize! :approve_posts, item.conversation
        item.mark_flagged_as(params[:flag_action])

        render json: 'ok'
      end

    end
  end
end
