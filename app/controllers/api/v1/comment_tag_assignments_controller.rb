module Api
  module V1

    class CommentTagAssignmentsController < Api::BaseController
      skip_authorization_check only: [:update, :destroy]

      def index
        conversation = Conversation.find_by(code: params[:conversation_code])
        authorize! :tag_comment, conversation
        tag_assignments = CommentTagAssignment.where(conversation_id: conversation.id)
        tag_ids = tag_assignments.map(&:tag_id).uniq!
        tags = Tag.where(id: tag_ids)
        document = {
            links:{
                'tag_assignment.tags' => {
                    type: 'tags'
                }
            },
            tag_assignments: tag_assignments.as_json,
            linked:{
                tags: tags.as_json
            }
        }
        render json: document
      end

      def create
        comment = Comment.find_by(id: params[:com_id])
        if comment.nil?
          authorize! :user, User
          return render json: {errors: { base: ["Comment not found with id #{params[:com_id]}"] } }, status: :not_found
        end

        authorize! :tag_comment, comment.conversation
        begin
          tagAssignment = CommentTagAssignment.create(
              tag_id: params[:tag_id],
              tag_text: params[:tag_text],
              user_id: current_user.id,
              conversation_id: comment.conversation_id,
              conversation_code: comment.conversation.code
          )
          comment.comment_tag_assignments << tagAssignment

        rescue ActiveRecord::RecordNotUnique
          # if the tag assignment request wasn't unique
          # then return the record I tried to duplicate
          # so the client knows the assignment exists
          tagAssignment = CommentTagAssignment.find_by(
            tag_id: tagAssignment.tag_id,
            comment_id: tagAssignment.comment_id,
            user_id: tagAssignment.user_id
          )
        end

        if !tagAssignment.errors.empty?
          Rails.logger.debug "found errors"
          return render json: {errors: tagAssignment.errors}, status: :not_found
        else
          Rails.logger.debug "no errors and is new record"
          render json: tagAssignment.as_json

        end
      end

      def update
        tagAssignment = CommentTagAssignment.find_by(id: params[:id])
        tagAssignment.update_attributes({star: params[:star]})
        render json: tagAssignment.as_json
      end

      def destroy
        tagAssignment = CommentTagAssignment.find_by(id: params[:id])

        if tagAssignment.nil?
          head :not_found
        elsif tagAssignment.user_id && tagAssignment.user_id != current_user.id
          head :unauthorized
        else
          tagAssignment.destroy
          head :no_content
        end
      end

    end

  end
end
