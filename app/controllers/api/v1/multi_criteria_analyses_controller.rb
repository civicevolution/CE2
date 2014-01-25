module Api
  module V1
    class MultiCriteriaAnalysesController < Api::BaseController
      skip_authorization_check only: [:update, :firebase_token, :save_panel_weight]

      def firebase_token
        mca = MultiCriteriaAnalysis.find(params[:id])
        #authorize! :edit_theme_comment, conversation
        firebase_auth_data = {} # anyone can read for right now
        render json: {"firebase_token" => Firebase::FirebaseTokenGenerator.new(Firebase.auth).create_token(firebase_auth_data) }
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

    end
  end
end