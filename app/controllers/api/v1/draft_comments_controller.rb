module Api
  module V1

    class DraftCommentsController < Api::BaseController
      skip_authorization_check only: [:index, :create, :update, :destroy]

      def index
        #authorize! :index, Conversation
        userDraftComments = current_user.nil? ? [] : DraftComment.where(user_id: current_user.id)
        anonymousDraftComments = params[:draft_comment_codes].nil? ? [] : DraftComment.where(code: params[:draft_comment_codes].split(','))
        draft_comments = userDraftComments + anonymousDraftComments
        draft_comments.uniq!
        draft_comments.sort!{|a,b| a.id <=> b.id}
        respond_with draft_comments.as_json
      end

      def create
        params[:user_id] = current_user.id
        draft = DraftComment.create( params )
        render json: draft.as_json
      end

      def update
        draft = DraftComment.find_by( code: params[:code] )
        draft.update_attributes({data: params[:data], user_id: current_user.id})
        render json: draft.as_json
      end

      def destroy
        draft = DraftComment.find_by( code: params[:id] )

        if draft.nil?
          render json: {message: "Draft comment could not be found for destroy"}, status: :not_found
        elsif draft.user_id && draft.user_id != current_user.id
          render json: {message: "You are not authorized to delete this draft comment"}, status: :unauthorized
        else
          draft.destroy
          head :no_content
        end
      end

    end

  end
end
