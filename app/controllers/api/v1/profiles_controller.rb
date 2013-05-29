module Api
  module V1

    class ProfilesController < Api::BaseController
      load_and_authorize_resource

      def create
        params[:attachment][:user_id] = current_user.id
        params[:attachment][:attachable_id] = 0
        params[:attachment][:attachable_type] = 'Undefined'

        if env['HTTP_ACCEPT'].match(/json/)
          respond_with Attachment.create(params[:attachment])
        else
          respond_with Attachment.create(params[:attachment]), :content_type=>'text/plain'
        end
      end


      def update
        logger.debug "update the comment with id: #{params[:id]}"
        respond_with Attachment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Attachment.destroy(params[:id])
      end

      def upload_photo
        logger.debug "upload_photo user_id: #{current_user.id}"

        profile = current_user.profile
        if !profile
          profile = Profile.create
          current_user.profile = profile
        end

        profile.photo = params[:photo][:photo]
        profile.save

        respond_with profile
      end

    end

  end
end
