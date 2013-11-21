module Api
  module V1
    class McaRatingsController < Api::BaseController
      skip_authorization_check only: [:update]

      def update
        evaluation = McaOptionEvaluation.find(params[:mca_option_evaluation_id])
        raise "CivicEvolution::RateCriteriaNotAllowed for non-owner" unless evaluation.user_id == current_user.id
        rating = McaRating.where(mca_option_evaluation_id: params[:mca_option_evaluation_id], mca_criteria_id: params[:mca_criteria_id]).first_or_create
        rating.rating = params[:rating]
        rating.save
        render json: { status: 'accepted', mca_option_evaluation_id: rating.mca_option_evaluation_id, mca_criteria_id: rating.mca_criteria_id, rating: rating.rating}
      end

    end
  end
end