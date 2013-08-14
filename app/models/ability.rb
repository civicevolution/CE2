class Ability
  include CanCan::Ability


  #  I define the actions that are allowed for each role
  #  my can block is only applicable to conversations at this time
  #  I look up all the roles for this use for this conversation
  #  I then look for the action to be included in the conversation_actions_by_role arrays
  #  for each role held by this user for this conversation

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    conversation_actions_by_role = {}
    conversation_actions_by_role[:probationary_participant] = %i( show request_notification rate_comment history post_prescreen bookmark attachment )
    conversation_actions_by_role[:participant] = %i( post_no_attachments  ).concat conversation_actions_by_role[:probationary_participant]
    conversation_actions_by_role[:trusted_participant] = %i( post_any invite private_message  ).concat conversation_actions_by_role[:participant]
    conversation_actions_by_role[:curator] = %i( edit_summary summary_comment_order edit_cta group_message approve_posts approve_participants moderate_posts ).concat conversation_actions_by_role[:trusted_participant]
    conversation_actions_by_role[:conversation_admin] = %i( edit_title privacy tags schedule publish participant_privileges ).concat conversation_actions_by_role[:curator]

    #puts conversation_actions_by_role[:conversation_admin].inspect

    can do |action, subject_class, subject|
      auth = false
      if [Conversation, ConversationComment, SummaryComment, TitleComment, CallToActionComment].include? subject.class
        roles = Role.joins(:users).where(users: {id: user.id}, resource_type: subject_class, resource_id: subject.id).pluck(:name)
        roles.each do |role|
          auth = true if conversation_actions_by_role[ role.to_sym ].include?( action )
        end
      end
      auth
    end

    # now add can read if the conversation is public

    can :show_summary_only, Conversation do |conversation|
      conversation.privacy['summary'] == "true"
    end

    can :show, Conversation do |conversation|
      conversation.privacy['comments'] == "true"
    end

    can :post_unknown, Conversation do |conversation|
      conversation.privacy['unknown_users'] == "true"
    end

    # things anyone can do
    can :user, User
    can :upload_photo, Profile
    can :create, Conversation
    can :index, Conversation




  end
end

    #case
    #  #when (user.has_role? :admin)
    #  #  can :manage, :all
    #
    #  when (user.has_role? :participant)
    #    can :read, :all
    #    can :update, Comment
    #    can :create, Comment
    #    can :destroy, Comment
    #    can :history, Comment
    #    can :rate, Comment
    #
    #    can :manage, Attachment
    #    can :manage, Profile
    #
    #    can :manage, Conversation
    #
    #  else
    #    can :read, [ Conversation, Comment ]
    #
    #
    #end

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities