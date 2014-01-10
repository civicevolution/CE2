module Api
  module V1

    class ConversationsController < Api::BaseController
      skip_authorization_check only: [:group_data]
      #def default_serializer_options
      #  {
      #      root: false
      #  }
      #end

      def index
        authorize! :index, Conversation
        conversations = Conversation.all.includes(:title_comment)
        respond_with conversations, each_serializer: ConversationListAllSerializer
      end

      def show
        conversation = Conversation.find_by( code: params[:id] )
        session_id = request.session_options[:id]
        # determine if I can :show ()all comments) or try :show_summary_only
        if can?(:show, conversation)
          authorize! :show, conversation
          presenter = ConversationPresenter.new( conversation, current_user, session_id, :show_all )
          Modules::FayeRedis::add_session_to_redis(session_id, current_user, ["/#{params[:id]}"], [])
        else
          authorize! :show_summary_only, conversation
          presenter = ConversationPresenter.new( conversation, current_user, session_id, :show_summary_only )
          Modules::FayeRedis::add_session_to_redis(session_id, current_user, ["/#{params[:id]}"], [])
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
        if request.method == 'GET'
          authorize! :view_themes, conversation
          title = conversation.title_comment.try{ |title_comment| title_comment.text}
          render json: title
          return
        else
          authorize! :edit_title, conversation
          title_comment = TitleComment.where(conversation_id: conversation.id).first_or_create do |tc|
            tc.user_id = current_user.id
          end
          title_comment.text = params[:title]
          title_comment.save
        end
        respond_with title_comment
      end

      def update_comment_order
        Rails.logger.debug "api/conversations_controller.update_comment_order for conversation #{params[:id]}"

        conversation = Conversation.find_by(code: params[:id])
        authorize! :update_comment_order, conversation

        ids_with_order_id = Conversation.update_comment_order( params[:id], params[:ordered_ids] )
        if !ids_with_order_id.empty?
          message = { class: 'Conversation', action: 'update_comment_order', data: {conversation_code: params[:id], ordered_ids: ids_with_order_id }, updated_at: Time.now.getutc, source: "RT-Notification" }
          channel = "/#{conversation.code}"
          Modules::FayeRedis::publish(message,channel)
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

      def theme_data
        conversation = Conversation.find_by(code: params[:id])
        authorize! :edit_theme_comment, conversation
        presenter = ConversationThemePresenter.new( conversation, current_user, :show_all )
        respond_with presenter.conversation, serializer: ConversationThemeDataSerializer
      end

      def parked_comments
        conversation = Conversation.find_by(code: params[:id])
        authorize! :edit_theme_comment, conversation
        respond_with conversation.parked_comments
      end

      def group_data
        conversation = Conversation.find_by(code: params[:id])
        authorize! :view_table_comments, conversation
        respond_with conversation, serializer: ConversationGroupDataSerializer
      end

      def themes
        conversation = Conversation.find_by(code: params[:id])
        authorize! :view_themes, conversation
        themes = conversation.themes
        respond_with themes
      end

    end
  end
end
