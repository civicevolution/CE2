module Api
  module V1

    class ConversationsController < Api::BaseController
      #def default_serializer_options
      #  {
      #      root: false
      #  }
      #end

      def index
        authorize! :index, Conversation
        respond_with Conversation.all, scope: { shallow_serialization_mode: true}
      end

      def show
        conversation = Conversation.find_by( code: params[:id] )
        # determine if I can :show ()all comments) or try :show_summary_only
        if can?(:show, conversation)
          authorize! :show, conversation
          presenter = ConversationPresenter.new( conversation, current_user, :show_all )
        else
          authorize! :show_summary_only, conversation
          presenter = ConversationPresenter.new( conversation, current_user, :show_summary_only )
        end

        respond_with presenter.conversation
      end

      def create
        authorize! :create, Conversation
        # create a new conversation with defaults from civicevolution.yml
        conversation = Conversation.create( user_id: current_user.id )
        current_user.add_role :conversation_admin, conversation
        respond_with conversation
      end

      def title
        conversation = Conversation.find_by(code: params[:id])
        authorize! :edit_title, conversation
        title_comment = TitleComment.where(conversation_id: conversation.id).first_or_create do |tc|
          tc.user_id = current_user.id
        end
        title_comment.text = params[:title]
        title_comment.save
        respond_with title_comment
      end

      def summary_comment_order
        Rails.logger.debug "api/conversations_controller.summary_comment_order for conversation #{params[:id]}"

        conversation = Conversation.find_by(code: params[:id])
        authorize! :summary_comment_order, conversation

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
        authorize! :privacy, conversation
        conversation.update_privacy current_user, params[:privacy]
        render json: 'ok'
      end

      def tags
        conversation = Conversation.find_by(code: params[:id])
        authorize! :tags, conversation
        conversation.update_tags current_user, params[:tags]
        render json: 'ok'
      end

      def schedule
        conversation = Conversation.find_by(code: params[:id])
        authorize! :schedule, conversation
        conversation.update_schedule current_user, {start: params[:start], end: params[:end]}
        render json: 'ok'
      end

      def publish
        conversation = Conversation.find_by(code: params[:id])
        authorize! :publish, conversation
        conversation.publish current_user
        render json: 'ok'
      end

      def guest_posts
        conversation = Conversation.find_by(code: params[:id])
        authorize! :approve_posts, conversation
        guest_posts = conversation.guest_posts
        respond_with guest_posts
      end

      def pending_comments
        conversation = Conversation.find_by(code: params[:id])
        authorize! :approve_posts, conversation
        pending_comments = conversation.pending_comments
        respond_with pending_comments
      end

      def flagged_comments
        conversation = Conversation.find_by(code: params[:id])
        authorize! :approve_posts, conversation
        flagged_comments = conversation.flagged_comments
        respond_with flagged_comments, each_serializer: FlaggedCommentSerializer
      end

      def participants_roles
        conversation = Conversation.find_by(code: params[:id])
        authorize! :show_participants, conversation
        participants_roles = conversation.participants_roles
        respond_with participants_roles #, each_serializer: ParticipantSerializer
      end

      def invited_guests
        conversation = Conversation.find_by(code: params[:id])
        authorize! :show_participants, conversation
        invited_guests = conversation.invites.order('id DESC')
        respond_with invited_guests, each_serializer: InvitedGuestSerializer
      end

      def update_role
        conversation = Conversation.find_by(code: params[:id])
        authorize! :update_role, conversation
        conversation.update_role( params[:user_code], params[:role] )
        render json: 'ok'
      end

      def stats
        conversation = Conversation.find_by(code: params[:id])
        authorize! :show_participants, conversation
        stats = conversation.stats
        respond_with stats
      end

    end

  end
end
