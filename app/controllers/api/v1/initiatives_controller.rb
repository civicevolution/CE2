module Api
  module V1

    class InitiativesController < Api::BaseController
      #load_and_authorize_resource

      def issues
        if params[:id] =~ /\A\d*\z/
          initiative = Initiative.find(params[:id])
        else
          initiative = Initiative.where(munged_title: params[:id]).first
        end

        respond_with initiative, scope: { list_issues_only_mode: true}
      end

      def index
        #respond_with Conversations.comments.where(id: params[:id])
        respond_with Conversations.find(  params[:id])
        #Conversation.first.summary_comments(:includes=> :author)
      end

      def show
        conversation = Conversation.includes(:comments).find(params[:id])
        current_user_id = current_user.try{ |user| user.id} || nil

        my_ratings = Rating.where( user_id: current_user_id, ratable_id: conversation.comments.map(&:id), ratable_type: 'Comment').inject({}){|hash, r| hash[r.ratable_id] = r.rating ; hash }
        conversation.comments.each{|com| com.my_rating = my_ratings[com.id]}
        firebase_auth_data =    { userid: "#{current_user_id}",
                                  #issues_read: { "#{conversation.issue_id}" => true },
                                  #issues_write: { "#{conversation.issue_id}" => true },
                                  conversations_read: { "#{conversation.id}" => true },
                                  conversations_write: { "#{conversation.id}" => true }

        }
        conversation.firebase_token = Firebase::FirebaseTokenGenerator.new(Firebase.auth).create_token(firebase_auth_data)


        respond_with conversation
      end

      def create
        respond_with ConversationComment.create(params[:comment])
      end

      def update
        respond_with Comment.update(params[:id], params[:comment])
      end

      def destroy
        respond_with Comment.destroy(params[:id])
      end

      def summary_comment_order
        Rails.logger.debug "api/conversations_controller.summary_comment_order for conversation #{params[:id]}"
        ids_with_order_id = Conversation.reorder_summary_comments( params[:id], params[:ordered_ids] )
        if !ids_with_order_id.empty?
          conversation = Conversation.find( params[:id] )
          Firebase.base_uri = "https://civicevolution.firebaseio.com/issues/#{conversation.question.issue_id}/conversations/#{conversation.id}/updates/"
          Firebase.push '', { class: 'Conversation', action: 'update_summary_comment_order', data: {conversation_id: params[:id], ordered_ids: ids_with_order_id }, updated_at: Time.now.getutc, source: "RoR-Firebase" }
        end

        render json: 'ok'
      end
    end

  end
end