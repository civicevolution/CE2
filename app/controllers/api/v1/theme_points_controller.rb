module Api
  module V1

    class ThemePointsController < Api::BaseController
      skip_authorization_check only: [:save, :located_points ]

      def save
        #Rails.logger.debug "ThemePointsController#save"
        code = params[:id]
        group_id = current_user.last_name.to_i
        voter_id = params[:data][:voter_id]
        # destroy any votes they have set already
        ThemePoint.where(code: code, group_id: group_id, voter_id: voter_id).destroy_all
        params[:data][:vote_points].each do |alloc|
          ThemePoint.create(code: code, group_id: group_id, voter_id: voter_id, theme_id: alloc[:theme_id], points: alloc[:points])
        end
        render json: 'ok'
      end

    end

  end
end
