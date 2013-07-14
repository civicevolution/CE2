module Api
  module V1

    class AttachmentsController < Api::BaseController
      load_and_authorize_resource

      def create
        params[:attachment][:user_id] = current_user.id
        params[:attachment][:attachable_id] = 0
        params[:attachment][:attachable_type] = 'Undefined'

        attachment = Attachment.create(params[:attachment])
        Conversation.find(params[:conversation_code]).attachments << attachment

        if env['HTTP_ACCEPT'].match(/json/)
          respond_with attachment
        else
          respond_with attachment, :content_type=>'text/plain'
        end
      end


      def update
        logger.debug "update the comment with id: #{params[:id]}"
        respond_with Attachment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Attachment.destroy(params[:id])
      end

    end

  end
end
