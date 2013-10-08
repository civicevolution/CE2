module Api
  module V1

    class ThemeVotesController < Api::BaseController
      skip_authorization_check only: [:save ]

      def save
        #Rails.logger.debug "ThemeVotesController#save"
        voter_id = params[:data][:voter_id]
        group_id = current_user.last_name.to_i
        # destroy any votes they have set already
        ThemeVote.where(voter_id: voter_id, group_id: group_id).destroy_all
        votes = []
        params[:data][:selected_ids].each do |vote|
          votes.push ThemeVote.create(group_id: group_id, voter_id: voter_id, theme_id: vote[:theme_id].to_i)
        end
        render json: votes
      end


    end

  end
end
