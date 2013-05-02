module Api
  module V1

    class UsersController < Api::BaseController

      def user
        current_user
        respond_with current_user
      end

    end
  end
end