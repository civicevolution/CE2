module Api
  module V1
    class UsersController < Api::BaseController
      skip_authorization_check only: [:user]

      def user
        current_user
        current_user.session_id = request.session_options[:id]
        respond_with current_user
      end

    end
  end
end