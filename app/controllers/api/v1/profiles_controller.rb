module Api
  module V1

    class ProfilesController < Api::BaseController

      def create
        params[:attachment][:user_id] = current_user.id
        params[:attachment][:attachable_id] = 0
        params[:attachment][:attachable_type] = 'Undefined'

        attachment = Attachment.create(params[:attachment])
        if env['HTTP_ACCEPT'].match(/json/)
          respond_with attachment
        else
          respond_with attachment, :content_type=>'text/plain'
        end
      end


      def update
        logger.debug "update the comment with id: #{params[:id]}"
        attachment = Attachment.update(params[:id], params[:comment])
        respond_with attachment
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
