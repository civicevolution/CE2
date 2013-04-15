module Api
  module V1

    class CommentsController < Api::BaseController
      load_and_authorize_resource
      
      def index
        respond_with Comment.all
      end

      def show
        respond_with Comment.find(params[:id])
      end

      def create
        respond_with Comment.create(params[:comment])
      end

      def update
        respond_with Comment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Comment.destroy(params[:id])
      end

    end

  end
end
