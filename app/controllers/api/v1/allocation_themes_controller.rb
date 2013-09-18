module Api
  module V1

    class AllocationThemesController < Api::BaseController
      skip_authorization_check only: [:save, :list, :allocated_points ]

      def list
        allocation_themes = AllocationTheme.find_by(code: params[:id]).allocation_themes
        render json: allocation_themes
      end

      def save
        Rails.logger.debug "AllocationThemesController#save"
        group_id = current_user.last_name.to_i
        # destroy any votes they have set already
        ThemePoint.where(group_id: group_id).destroy_all
        params[:data].each do |alloc|
          ThemePoint.create(group_id: group_id, theme_id: alloc[:id], points: alloc[:points])
        end
        render json: 'ok'
      end

      def allocated_points
        allocated_points = AllocationTheme.find_by(code: params[:id]).allocated_points
        render json: allocated_points
      end

    end

  end
end
