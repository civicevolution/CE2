module Api
  module V1
    class McaOptionEvaluationsController < Api::BaseController
      skip_authorization_check only: [:remove_evaluation_assignment]

      def remove_evaluation_assignment
        evaluation = McaOptionEvaluation.find(params[:id])
        #authorize! :edit_theme_comment, conversation
        evaluation.update_attribute(:status, 'deleted')

        render json: {remove_evaluation_assignment: 'ok', option_evaluation_id: evaluation.id }
      end

    end
  end
end