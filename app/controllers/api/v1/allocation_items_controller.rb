module Api
  module V1

    class AllocationItemsController < Api::BaseController
      skip_authorization_check only: [:save, :six_options, :allocation_votes ]

      def save
        Rails.logger.debug "AllocationItemsController#save"
        group_id = current_user.last_name.to_i
        # destroy any votes they have set already
        ThemePoint.where(group_id: group_id).destroy_all
        params[:data].each do |alloc|
          ThemePoint.create(group_id: group_id, theme_id: alloc[:theme_id], points: alloc[:value])
        end


        render json: 'ok'
      end

      def six_options

        #get six items from the AllocationItems table
        items = AllocationItem.all.order('order_id ASC')
        render json: items

      end

      def allocation_votes


      end

    end

  end
end
