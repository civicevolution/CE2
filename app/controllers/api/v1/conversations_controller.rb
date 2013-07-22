module Api
  module V1

    class ConversationsController < Api::BaseController
      #load_and_authorize_resource
      #def default_serializer_options
      #  {
      #      root: false
      #  }
      #end

      def index
        respond_with Conversation.all, scope: { shallow_serialization_mode: true}
      end

      def show
        conversation = Conversation.includes(:comments).where( code: params[:id] ).first

        current_user_id = current_user.try{ |user| user.id} || nil

        my_ratings = Rating.where( user_id: current_user_id, ratable_id: conversation.comments.map(&:id), ratable_type: 'Comment').inject({}){|hash, r| hash[r.ratable_id] = r.rating ; hash }
        conversation.comments.each{|com| com.my_rating = my_ratings[com.id]}

        # everyone who can access this conversation can read the updates from Firebase
        firebase_auth_data = { conversations_read: { "#{conversation.code}" => true } }

        # only authenticated users can read their user channel or potentially write to the conversation channel on firebase
        if current_user_id
          firebase_auth_data['userid'] = "#{current_user_id}"
          firebase_auth_data['conversations_write'] = { "#{conversation.code}" => true }
        end

        conversation.firebase_token = Firebase::FirebaseTokenGenerator.new(Firebase.auth).create_token(firebase_auth_data)

        respond_with conversation
      end

      def create
        # create a new conversation with defaults from civicevolution.yml
        respond_with Conversation.create( user_id: current_user.id )
      end

      def update
        respond_with Comment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Comment.destroy(params[:id])
      end

      def title
        conversation = Conversation.where(code: params[:id]).first
        title_comment = TitleComment.where(conversation_id: conversation.id).first_or_create do |tc|
          tc.user_id = current_user.id
        end
        title_comment.text = params[:title]
        title_comment.save
        respond_with title_comment
      end

      def summary_comment_order
        Rails.logger.debug "api/conversations_controller.summary_comment_order for conversation #{params[:id]}"
        ids_with_order_id = Conversation.reorder_summary_comments( params[:id], params[:ordered_ids] )
        if !ids_with_order_id.empty?
          conversation = Conversation.find( params[:id] )
          #Firebase.base_uri = "https://civicevolution.firebaseio.com/issues/#{conversation.question.issue_id}/conversations/#{conversation.id}/updates/"
          Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{conversation.code}/updates/"
          Firebase.push '', { class: 'Conversation', action: 'update_summary_comment_order', data: {conversation_code: params[:id], ordered_ids: ids_with_order_id }, updated_at: Time.now.getutc, source: "RoR-Firebase" }
        end

        render json: 'ok'
      end

      def privacy
        Rails.logger.debug "api/conversations_controller.privacy for conversation #{params[:id]}"
        conversation = Conversation.where(code: params[:id]).first
        conversation.privacy = params[:privacy]
        conversation.save
        render json: 'ok'
      end

      def tags
        #Rails.logger.debug "api/conversations_controller.tags for conversation #{params[:id]}"
        conversation = Conversation.where(code: params[:id]).first
        conversation.update_tags params[:tags], current_user
        render json: 'ok'
      end

      def schedule
        Rails.logger.debug "api/conversations_controller.schedule for conversation #{params[:id]}"
        conversation = Conversation.where(code: params[:id]).first
        conversation.update_schedule start: params[:start], end: params[:end]
        render json: 'ok'
      end

    end

  end
end
