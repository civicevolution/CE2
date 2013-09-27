module Api
  module V1

    class AgendasController < Api::BaseController
      skip_authorization_check :only => [:agenda, :accept_role, :release_role]

      def agenda
        agenda = Agenda.find_by(code: params[:id])
        render json: agenda
      end

      def accept_role
        agenda = Agenda.find_by(code: params[:id])
        user = agenda.get_user_for_accept_role( current_user, params[:data] )
        sign_in(user)
        respond_with user
      end

      def release_role
        agenda = Agenda.find_by(code: params[:id])
        agenda.release_role( current_user )
        sign_out(current_user)
        render json: "Sign out successful"
      end

    end
  end
end
