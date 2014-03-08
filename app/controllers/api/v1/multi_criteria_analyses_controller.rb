module Api
  module V1
    class MultiCriteriaAnalysesController < Api::BaseController
      skip_authorization_check only: [:update, :save_panel_weight,:detailed_report]

      def update
        Rails.logger.debug "MultiCriteriaAnalysesController::update"
        mca = MultiCriteriaAnalysis.find(params[:mca_id])
        authorize! :add_mca, mca.agenda
        render json: mca.update(params[:key], params[:value])
      end

      def add_criteria
        Rails.logger.debug "MultiCriteriaAnalysesController::add_criteria"
        mca = MultiCriteriaAnalysis.find(params[:mca_id])
        authorize! :add_mca, mca.agenda
        render json: mca.add_criteria(params[:title])
      end

      def add_option
        Rails.logger.debug "MultiCriteriaAnalysesController::add_option"
        mca = MultiCriteriaAnalysis.find(params[:mca_id])
        authorize! :add_mca, mca.agenda
        render json: mca.add_option(params[:title])
      end


      def save_panel_weight
        mca = MultiCriteriaAnalysis.find(params[:id])
        #authorize! :edit_theme_comment, conversation
        details = mca.details
        mca.update_attribute(:details, {})
        details = {} if details.nil?
        details['panel_weight'] = params[:panel_weight]
        mca.update_attribute(:details, details)
        render json: "saved panel_weight as #{details['panel_weight'] }"
      end

      def detailed_report
        mca = MultiCriteriaAnalysis.find(params[:id])
        #authorize! :detailed_report, conversation
        #render json: mca.as_json( except: [:created_at, :updated_at] )
        render json: mca.detailed_report
      end

    end
  end
end