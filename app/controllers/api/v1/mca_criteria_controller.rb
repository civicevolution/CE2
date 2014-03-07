module Api
  module V1
    class McaCriteriaController < Api::BaseController

      def update
        Rails.logger.debug "McaCriteriaController::update"
        criteria = McaCriteria.find(params[:criteria_id])
        authorize! :add_mca, criteria.mca.agenda
        render json: criteria.update(params[:key], params[:value])
      end

      def destroy
        Rails.logger.debug "McaCriteriaController::destroy"
        criteria = McaCriteria.find(params[:criteria_id])
        authorize! :add_mca, criteria.mca.agenda
        raise "CivicEvolution::AgendaCannotBeReset Not in test mode" unless criteria.mca.agenda.test_mode
        criteria.destroy
        render json: criteria
      end

    end
  end
end