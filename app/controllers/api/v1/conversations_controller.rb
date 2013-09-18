module Api
  module V1

    class ConversationsController < Api::BaseController
      skip_authorization_check only: [:theme_votes, :group_data, :live_event_data, :import_live_event_data]
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
          #Firebase.base_uri = "https://civicevolution.firebaseio.com/issues/#{conversation.question.issue_id}/conversations/#{conversation.id}/updates/"
          Firebase.base_uri = "https://civicevolution.firebaseio.com/conversations/#{conversation.code}/updates/"
          Firebase.push '', { class: 'Conversation', action: 'update_comment_order', data: {conversation_code: params[:id], ordered_ids: ids_with_order_id }, updated_at: Time.now.getutc, source: "RoR-Firebase" }
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
        presenter = ConversationPresenter.new( conversation, current_user, :show_all )
        respond_with presenter.conversation, serializer: ConversationThemeDataSerializer
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

      def theme_votes
        render json: ThemeVote.theme_votes(params[:id])
      end

      def live_event_data
        data_set = StringIO.new
        # This writes all of the data to one file

        conversations = Conversation.where(id: params[:ids].scan(/\d+/).map(&:to_i))

        data_set.write( {"Conversations" => conversations.map{|c| c.attributes}}.to_yaml )

        user_ids = conversations.map(&:user_id).uniq

        comments = []
        conversations.each do |c|
          comments.concat c.comments
        end

        data_set.write( {"Comments" => comments.map{|c| c.attributes}}.to_yaml )

        comment_ids = comments.map(&:id)
        user_ids.concat comments.map(&:user_id).uniq

        comment_versions = CommentVersion.where(item_type: 'Comment', item_id: comment_ids)
        data_set.write( {"CommentVersions" => comment_versions.map{|c| c.attributes}}.to_yaml )


        comment_threads = CommentThread.where(parent_id: comment_ids)
        data_set.write( {"CommentThreads" => comment_threads.map{|c| c.attributes}}.to_yaml )

        pro_con_vote = ProConVote.where(comment_id: comment_ids)
        data_set.write( {"ProConVotes" => pro_con_vote.map{|c| c.attributes}}.to_yaml )


        theme_votes = ThemeVote.where(theme_id: comment_ids)
        data_set.write( {"ThemeVotes" => theme_votes.map{|c| c.attributes}}.to_yaml )

        user_ids.concat theme_votes.map(&:group_id).uniq
        user_ids.uniq!
        users = User.where(id: user_ids)
        user_recs = {}
        users.each{|u| user_recs[u.id] = {email: u.email, first_name: u.first_name, last_name: u.last_name}}
        data_set.write( {"Users" => user_recs}.to_yaml )

        send_data data_set.string, :filename => "live_event_data.yaml", :type =>  "x-yaml"

      end

      def import_live_event_data

        event_doc = YAML::load_stream( File.open( "#{Rails.root}/live_event_data.yaml" ) )

        users = event_doc[6]["Users"]
        users.each_pair do |id,details|
          user = User.find_by(email: details[:email])
          if user
            #puts "old user_id: #{id}, new user_id: #{user.id} for details: #{details}"
            details[:new_user_id] = user.id
          else
            #puts "Didn't find matching user for old user_id: #{id} for details: #{details}"
          end
        end

        conversations_details = {}
        event_doc[0]["Conversations"].each do |details|
          conversations_details[details['id']] = details
          conversation = Conversation.new
          details.each_pair do |key,value|
            #puts "#{key}: #{value}"
            conversation[key] = value unless ['id','code'].include?(key)
          end
          conversation.user_id = users[details["user_id"] ][:new_user_id]
          #puts conversation.inspect
          conversation.save
          details[:new_id] = conversation.id
          details[:new_code] = conversation.code
        end


        votes = {}
        event_doc[4]["ProConVotes"].each do |v|
          votes[v['comment_id']] = {pro: v["pro_votes"], con: v["con_votes"]}
        end

        votes.each{|k,v| puts "#{k}: #{v.inspect}"}

        comment_details = {}
        event_doc[1]["Comments"].each do |details|
          comment_details[details['id']] = details
          # details = comment_details[0]
          #puts details.inspect
          comment = if details['type'] == 'TableComment'
                      TableComment.new
                    elsif details['type'] == 'ThemeComment'
                      ThemeComment.new
                    else
                      Comment.new
                    end
          details.each_pair do |key,value|
            #puts "#{key}: #{value}"
            comment[key] = value unless ['id','conversation_id', 'new_id'].include?(key)
          end
          comment.user_id = users[details["user_id"] ][:new_user_id]
          comment.conversation_id = conversations_details[details["conversation_id"] ][:new_id]
          #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
          vote = votes[ details['id']]
          if vote
            comment.pro_votes = vote[:pro] || 0
            #Rails.logger.debug "vote[:pro]: #{vote[:pro]}"
            comment.con_votes = vote[:con] || 0
          end
          #puts comment.inspect
          comment.post_process_disabled = true
          comment.save
          details[:new_id] = comment.id
        end


        event_doc[2]["CommentVersions"].each do |details|
          #puts details.inspect
          comment_version = CommentVersion.new
          details.each_pair do |key,value|
            comment_version[key] = value unless ['id'].include?(key)
          end
          comment_version.item_id = comment_details[details["item_id"] ][:new_id]
          #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
          #puts comment_version.inspect
          comment_version.save
        end

        event_doc[5]["ThemeVotes"].each do |details|
          puts details.inspect
          theme_vote = ThemeVote.new
          details.each_pair do |key,value|
            theme_vote[key] = value unless ['id'].include?(key)
          end
          theme_vote.group_id = users[details["group_id"] ][:new_user_id]
          theme_vote.theme_id = comment_details[details["theme_id"] ][:new_id]
          #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
          puts theme_vote.inspect
          theme_vote.save
        end

        event_doc[3]["CommentThreads"].each do |details|
          puts details.inspect
          comment_thread = CommentThread.new
          details.each_pair do |key,value|
            comment_thread[key] = value unless ['id'].include?(key)
          end
          comment_thread.child_id = comment_details[details["child_id"] ][:new_id]
          comment_thread.parent_id = comment_details[details["parent_id"] ][:new_id]
          #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
          puts comment_thread.inspect
          comment_thread.save
        end

        render json: 'ok'
      end
    end
  end
end
