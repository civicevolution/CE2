module Api
  module V1
    class MultiCriteriaAnalysesController < Api::BaseController
      skip_authorization_check only: [:update, :firebase_token]

      def firebase_token
        mca = MultiCriteriaAnalysis.find(params[:id])
        #authorize! :edit_theme_comment, conversation
        firebase_auth_data = {} # anyone can read for right now
        render json: {"firebase_token" => Firebase::FirebaseTokenGenerator.new(Firebase.auth).create_token(firebase_auth_data) }
      end

    end
  end
end