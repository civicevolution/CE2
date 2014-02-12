module Api
  module V1

    class RecommendationVotesController < Api::BaseController
      skip_authorization_check only: [:save ]

      def save
        conversation_id = Conversation.find_by(code: params[:id]).id
        group_id = current_user.last_name.to_i
        Rails.logger.info "Save this vote conversation_id: #{conversation_id}, group_id: #{group_id}: data: #{params[:data].as_json}"
        # destroy any votes they have set already
        #RecommendationVote.where(conversation_id: conversation_id, group_id: group_id).destroy_all
        RecommendationVote.destroy_all(conversation_id: conversation_id, group_id: group_id)
        votes = []
        params[:data].each do |vote|
          rec_vote = RecommendationVote.create(conversation_id: conversation_id, group_id: group_id, recommendation: vote[:vote_key].to_i, num_of_votes: vote[:num_votes].to_i)
          votes.push({group_id: rec_vote.group_id, conversation_id: rec_vote.conversation_id, recommendation: rec_vote.recommendation, num_of_votes: rec_vote.num_of_votes})
        end
        render json: votes
      end


    end

  end
end
