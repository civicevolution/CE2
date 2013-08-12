module Api
  module V1

    class BookmarksController < Api::BaseController

      def index
        #if params[:ids]
        #  respond_with Comment.includes(:author).where(id: params[:ids].scan(/\d+/) )
        #else
        #  respond_with Comment.includes(:author).all
        #end
      end

      def show
        #respond_with Comment.find(params[:id])
        ##render :json => Comment.find(params[:id]), :serializer => CommentSerializer
      end

      def create
        Rails.logger.debug "Create the bookmark with params: #{params.inspect}"

        # TODO: they should only be able to bookmark if they have access to this conversation
        conversation =
          case params[:type]
            when "Comment"
              Comment.find(params[:id]).conversation
            when "Conversation"
              Conversation.find_by(code: params[:id])
          end
        authorize! :bookmark, conversation
        params[:id] = conversation.id if params[:type] == "Conversation"

        bookmark = Bookmark.where(user_id: current_user.id, target_type: params[:type], target_id: params[:id] ).first_or_create do |bookmark|
          bookmark.version = params[:version]
        end
        respond_with bookmark

      end

      def destroy
        Rails.logger.debug "Destroy the bookmark with params: #{params.inspect}"

        # TODO: they should only be able to bookmark if they have access to this conversation
        conversation =
            case params[:type]
              when "Comment"
                Comment.find(params[:id]).conversation
              when "Conversation"
                Conversation.find_by(code: params[:id])
            end
        authorize! :bookmark, conversation
        params[:id] = conversation.id if params[:type] == "Conversation"

        bookmark = Bookmark.find_by(user_id: current_user.id, target_type: params[:type], target_id: params[:id] )
        bookmark.destroy unless !bookmark

        render json: 'ok'
      end

    end

  end
end
