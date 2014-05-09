module Api
  module V1
    class UsersController < Api::BaseController
      skip_authorization_check only: [:user]

      def user
        respond_with current_user
      end

    end
  end
end