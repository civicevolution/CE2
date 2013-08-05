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
        conversation = Conversation.includes(:comments).find_by( code: params[:id] )

        current_user_id = current_user.try{ |user| user.id} || nil

        comment_ids = conversation.comments.map(&:id)
        my_ratings = Rating.where( user_id: current_user_id, ratable_id: comment_ids, ratable_type: 'Comment').inject({}){|hash, r| hash[r.ratable_id] = r.rating ; hash }
        my_bookmarks = Bookmark.where( user_id: current_user_id, target_id: comment_ids, target_type: 'Comment').inject({}){|hash, b| hash[b.target_id] = true ; hash }
        conversation.comments.each do |com|
          com.my_rating = my_ratings[com.id]
          com.bookmark = my_bookmarks[com.id]
        end

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
        conversation = Conversation.create( user_id: current_user.id )
        respond_with conversation
      end

      def title
        conversation = Conversation.find_by(code: params[:id])
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
        conversation = Conversation.find_by(code: params[:id])
        conversation.update_privacy current_user, params[:privacy]
        render json: 'ok'
      end

      def tags
        conversation = Conversation.find_by(code: params[:id])
        conversation.update_tags current_user, params[:tags]
        render json: 'ok'
      end

      def schedule
        conversation = Conversation.find_by(code: params[:id])
        conversation.update_schedule current_user, {start: params[:start], end: params[:end]}
        render json: 'ok'
      end

      def publish
        conversation = Conversation.find_by(code: params[:id])
        conversation.publish current_user
        render json: 'ok'
      end

    end

  end
end
