module Api
  module V1

    class GuestPostsController < Api::BaseController

      def accept
        Rails.logger.debug "Accept the guest post with params: #{params.inspect}"
        guest_post = GuestPost.find(params[:id])
        guest_post.accept_join = params[:accept_join]
        authorize! :approve_posts, guest_post.conversation
        guest_post.accept(current_user)

        render json: 'ok'
      end

      def decline
        Rails.logger.debug "Decline the guest post with params: #{params.inspect}"
        guest_post = GuestPost.find(params[:id])
        guest_post.accept_join = params[:accept_join]
        authorize! :approve_posts, guest_post.conversation
        guest_post.decline(current_user)

        render json: 'ok'
      end

    end

  end
end
