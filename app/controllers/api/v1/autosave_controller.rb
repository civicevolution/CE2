module Api
  module V1

    class AutosaveController < Api::BaseController
      skip_authorization_check only: [:save, :load]

      def save
        (status, code_action, code) = Autosave.save(current_user.try{|user| user.id}, session[:autosave_code], params[:data])

        if code_action == :store
          session[:autosave_code] = code
        elsif code_action == :clear
          session.delete :autosave_code
        end
        render json: status
      end

      def load
        (data, code_action, code) = Autosave.load(current_user.try{|user| user.id}, session[:autosave_code])

        if code_action == :clear
          session.delete :autosave_code
        end
        render json: data
      end

    end

  end
end
