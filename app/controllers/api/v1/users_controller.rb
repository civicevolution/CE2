module Api
  module V1
    class UsersController < Api::BaseController
      skip_authorization_check only: [:user]

      def user
        user = current_user# || User.find(1)

        user.session_id = request.session_options[:id] unless user.nil?
        #user.csrf_token = form_authenticity_token unless user.nil?
        respond_with user
      end

    end
  end
end