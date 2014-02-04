module Api
  module V1

    class RecommendationVotesController < Api::BaseController
      skip_authorization_check only: [:save ]

      def save
        conversation_id = Conversation.find_by(code: params[:id]).id
        voter_id = params[:data][:voter_id]
        group_id = current_user.last_name.to_i
        recommendation = RecommendationVote.where(conversation_id: conversation_id, voter_id: voter_id, group_id: group_id).first_or_create
        recommendation.update_attribute(:recommendation, params[:data][:recommendation])
        render json: recommendation
      end


    end

  end
end
