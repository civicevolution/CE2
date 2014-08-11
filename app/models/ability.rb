class Ability
  include CanCan::Ability


  #  I define the actions that are allowed for each role
  #  my can block is only applicable to conversations at this time
  #  I look up all the roles for this use for this conversation
  #  I then look for the action to be included in the conversation_actions_by_role arrays
  #  for each role held by this user for this conversation

  @@conversation_actions_by_role = {}
  @@conversation_actions_by_role[:probationary_participant] = %i( show show_participants request_notification rate_comment history post_prescreen bookmark attachment )
  @@conversation_actions_by_role[:participant] = %i( post_no_attachments tag_comment  ).concat @@conversation_actions_by_role[:probationary_participant]
  @@conversation_actions_by_role[:trusted_participant] = %i( post_any invite private_message  ).concat @@conversation_actions_by_role[:participant]
  @@conversation_actions_by_role[:curator] = %i( edit_synthesis edit_summary update_comment_order edit_cta group_message approve_posts approve_participants moderate_posts ).concat @@conversation_actions_by_role[:trusted_participant]
  @@conversation_actions_by_role[:conversation_admin] = %i( edit_title privacy tags schedule publish update_role ).concat @@conversation_actions_by_role[:curator]

  @@conversation_actions_by_role[:scribe] = %i( tag_comment view_table_comments edit_table_comment post_prescreen history vote )
  @@conversation_actions_by_role[:themer] = %i( edit_synthesis edit_table_comment edit_theme_comment assign_comment_theme post_prescreen history update_comment_order destroy_theme_comment hide).concat @@conversation_actions_by_role[:scribe]
  @@conversation_actions_by_role[:coordinator] = %i( edit_synthesis publish_themes).concat @@conversation_actions_by_role[:themer]

  @@agenda_actions_by_role = {}
  @@agenda_actions_by_role[:admin] = %i( agenda_admin_details export_agenda delete_agenda refresh_agenda reset_agenda create_agenda add_conversation add_mca update_agenda update_conversation )


  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can do |action, subject_class, subject|
      auth = false
      if [Conversation, ConversationComment, SummaryComment, TitleComment, CallToActionComment].include? subject.class
        #roles = Role.joins(:users).where(users: {id: user.id}, resource_type: subject_class, resource_id: subject.id).pluck(:name)
        #roles.each do |role|
        #  auth = true if @conversation_actions_by_role[ role.to_sym ].include?( action )
        #end

        role = Role.joins(:users).find_by(users: {id: user.id}, resource_type: subject_class, resource_id: subject.id).try{|r| r.name}
        auth = true if role && @@conversation_actions_by_role[ role.to_sym ].include?( action )
      end

      if [Agenda].include?(subject.class) || [Agenda].include?(subject_class)
        # get all the roles I have for this class/instance and see if it has the action
        instance_roles = if subject.nil?
                          []
                        else
                          Role.joins(:users).where(users: {id: user.id}, resource_type: subject_class, resource_id: subject.id).pluck(:name)
                        end

        class_roles = Role.joins(:users).where(users: {id: user.id}, resource_type: subject_class, resource_id: nil).pluck(:name)

        roles = instance_roles.concat(class_roles).uniq
        roles.each do |role|
          if @@agenda_actions_by_role[ role.to_sym ].try{|actions| actions.include?( action )}
            auth = true
            break
          end
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

    can :index, Conversation
    can :flag, Conversation

    can :view_themes, Conversation
    can :list_iap2_conversations, Conversation

    if !user.id.nil?
      can :create, Conversation
    end


    if user.id == 1
      can :import, Agenda
      can :export, Agenda
      can :reset, Agenda
    end

  end

  def self.abilities(user, type, id)
    role = user && user.id ? Role.joins(:users).find_by(users: {id: user.id}, resource_type: type, resource_id: id).try{|r| r.name} || 'none' : 'none'
    {name: role, abilities: role ? @@conversation_actions_by_role[ role.to_sym ] || [] : [] }
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