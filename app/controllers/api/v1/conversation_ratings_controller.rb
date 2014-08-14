module Api
  module V1

    class ConversationRatingsController < Api::BaseController
      skip_authorization_check only: [:index, :create, :update, :destroy]

      def index
        #authorize! :index, Conversation
        ratings = ConversationRating.where(conversation_id: params[:conversation_id] )
        respond_with ratings.as_json
      end

      def create
        authorize! :conversation_rating, Conversation.find( params[:conversation_id] )
        record = ConversationRating.where(conversation_id: params[:conversation_id], user_id: current_user.id, rating_type: params[:type]).first_or_create
        record.rating_data = params[:data]
        record.save
        render json: record.as_json
      end

      #def update
      #  draft = DraftComment.find_by( code: params[:code] )
      #  draft.update_attributes({data: params[:data], user_id: current_user.id})
      #  render json: draft.as_json
      #end
      #
      #def destroy
      #  draft = DraftComment.find_by( code: params[:id] )
      #
      #  if draft.nil?
      #    render json: {message: "Draft comment could not be found for destroy"}, status: :not_found
      #  elsif draft.user_id && draft.user_id != current_user.id
      #    render json: {message: "You are not authorized to delete this draft comment"}, status: :unauthorized
      #  else
      #    draft.destroy
      #    head :no_content
      #  end
      #end

    end

  end
end
