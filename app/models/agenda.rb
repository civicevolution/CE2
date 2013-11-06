class Agenda < ActiveRecord::Base
  attr_accessible :title, :description, :code, :access_code, :template_name, :list, :status
  has_many :agenda_roles
  has_many :agenda_activities
  has_many :agenda_components
  has_many :agenda_component_threads

  has_many :reports, primary_key: :code, foreign_key: :agenda_code

  validate :code_is_unique, on: :create

  def code_is_unique
    self.code = Agenda.create_random_code
    while( Agenda.where(code: self.code).exists? ) do
      self.code = Agenda.create_random_code
    end
  end

  def self.create_random_code
    # I want each conversation to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...10).map{ o[rand(o.length)] }.join
  end

  def get_user_for_accept_role( data)
    #Rails.logger.debug "Agenda.sign_in my_id: #{self.id}"

    case data[:role]
      when "coordinator"
        data[:identifier] = 1
        email = "agenda-#{self.id}-coordinator-#{data[:identifier]}@civicevolution.org"
      when "themer"
        email = "agenda-#{self.id}-themer-#{data[:identifier]}@civicevolution.org"
      when "group"
        email = "agenda-#{self.id}-group-#{data[:identifier]}@civicevolution.org"
      when "reporter"
        data[:identifier] = 1
        email = "agenda-#{self.id}-reporter-#{data[:identifier]}@civicevolution.org"
    end

    rec = self.agenda_roles.find_by( name: data[:role], identifier: data[:identifier])
    if rec.nil?
      raise "CivicEvolution::AgendaAcceptNoRole No role for name:#{data[:role]}, identifier: #{data[:identifier]}"
    elsif !rec.access_code.nil? && rec.access_code != data[:access_code]
      raise "CivicEvolution::AgendaAcceptBadAccessCode Wrong access_code #{data[:access_code]} for name: #{data[:role]}, identifier: #{data[:identifier]}"
    end

    user = User.find_by(email: email)
    if user.nil?
      raise "CivicEvolution::AgendaAcceptNoUser No user for email: #{email}, name:#{data[:role]}, identifier: #{data[:identifier]}"
    end
    # return the user to controller to sign in
    user
  end

  def release_role(current_user)
    #Rails.logger.debug "Agenda.sign_out my_id: #{self.id}"

  end

  def agenda_data(current_user)
    agenda_details = self.get_details
    menu_data = []

    # get the role for this user
    role, role_id = self.get_role(current_user)
    if role
      # use agenda_details to construct the menu_data
      agenda_details["links"][role].each_value do |link|
        menu_data.push( {link_code: link["link_code"], title: link["title"], href: link["href"]})
      end
    end

    details = {
        title: self.title,
        munged_title: self.munged_title,
        description: self.description,
        test_mode: self.test_mode,
        code: self.code,
        menu_data: menu_data
    }
  end

  def munged_title
    self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]
  end

  def participant_report
    participant_report_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, 'participant_report').order(:starts_at)
    participant_report_components.map(&:participant_report_details)
  end

  def participant_report_data(params)
    conversation_code = params[:code]
    layout = params[:layout]
    agenda_details = self.details
    coordinator_user_id = agenda_details["coordinator_user_id"]

    case layout
      when 'key-themes'
        data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id} )

      when 'select-results'
        data = ThemeSelection.data_themes_select_results({"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id})
        data[:allocated_themes].each do|theme|
          theme[:count] = "(#{theme[:votes]})"
        end
      when 'allocation-results'
        data = ThemeAllocation.data_themes_allocation_results({"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id})
        data[:allocated_themes].each do|theme|
          theme[:count] = "#{theme[:points]}pts"
        end

      when 'select-worksheet'
        data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id} )
        data[:themes].each do |theme|
          theme[:text] = theme[:text].gsub(/\[quote.*\/quote\]/m,'')
        end
        data = {title: data[:title], worksheet_themes: data[:themes]}

      when 'allocation-worksheet'
        data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id} )
        data[:themes].each do |theme|
          theme[:text] = theme[:text].gsub(/\[quote.*\/quote\]/m,'')
        end
        data = {title: data[:title], worksheet_themes: data[:themes]}
    end
    data
  end

  def export_to_file(file)
    # This writes all of the data to the file and to be sent to the browser

    file.write( {"Agenda" => self.attributes}.to_yaml )

    agenda_components = self.agenda_components
    file.write( {"AgendaComponents" => agenda_components.map{|c| c.attributes}}.to_yaml )

    agenda_roles = self.agenda_roles
    file.write( {"AgendaRoles" => agenda_roles.map{|c| c.attributes}}.to_yaml )

    agenda_component_threads = self.agenda_component_threads
    file.write( {"AgendaComponentThreads" => agenda_component_threads.map{|c| c.attributes}}.to_yaml )

    # collect the conversation ids from the component inputs
    conversation_ids = []
    agenda_components.each do |c|
      c.input.each_pair do|key,value|
        if key.match(/conversation/)
          conversation_ids << value
        end
      end
    end

    conversations = Conversation.where(id: conversation_ids.flatten.uniq)

    file.write( {"Conversations" => conversations.map{|c| c.attributes}}.to_yaml )

    user_ids = conversations.map(&:user_id).uniq

    comments = []
    conversations.each do |c|
      comments.concat c.comments
    end

    file.write( {"Comments" => comments.map{|c| c.attributes}}.to_yaml )

    comment_ids = comments.map(&:id)
    user_ids.concat comments.map(&:user_id).uniq

    comment_versions = CommentVersion.where(item_type: 'Comment', item_id: comment_ids)
    file.write( {"CommentVersions" => comment_versions.map{|c| c.attributes}}.to_yaml )


    comment_threads = CommentThread.where(parent_id: comment_ids)
    file.write( {"CommentThreads" => comment_threads.map{|c| c.attributes}}.to_yaml )

    pro_con_vote = ProConVote.where(comment_id: comment_ids)
    file.write( {"ProConVotes" => pro_con_vote.map{|c| c.attributes}}.to_yaml )


    theme_votes = ThemeVote.where(theme_id: comment_ids)
    file.write( {"ThemeVotes" => theme_votes.map{|c| c.attributes}}.to_yaml )

    theme_points = ThemePoint.where(theme_id: comment_ids)
    file.write( {"ThemePoints" => theme_points.map{|c| c.attributes}}.to_yaml )

    # I should get parked_comments

    user_ids.concat theme_votes.map(&:group_id).uniq
    user_ids.uniq!
    users = User.where(id: user_ids)
    user_recs = {}
    users.each{|u| user_recs[u.id] = {email: u.email, first_name: u.first_name, last_name: u.last_name}}
    file.write( {"Users" => user_recs}.to_yaml )

  end

  def self.import(file)

    event_doc = YAML::load_stream( file )

    docs = {}
    event_doc.each do |doc|
      docs[ doc.keys[0] ] = doc[ doc.keys[0] ]
      puts doc.keys[0]
    end
    event_doc = nil

    # docs["Agenda"]
    # {"Agenda"=>{"id"=>1, "title"=>"Bangalore Sub-urban Rail Project: Potential for innovative financing and planning strategies",
    # "description"=>"Bangalore Sub-urban Rail Project", "code"=>"f3zp7xglzp", "access_code"=>"bingo", "template_name"=>"iap2", "list"=>nil,
    # "status"=>nil, "created_at"=>2013-10-08 08:02:09 UTC, "updated_at"=>2013-10-08 08:02:09 UTC}}

    agenda_details = docs["Agenda"]

    agenda = Agenda.new
    agenda_details.each_pair do |key,value|
      #puts "#{key}: #{value}"
      agenda[key] = value unless ['id','code'].include?(key)
    end
    #puts agenda.inspect
    agenda.save

    agenda_details[:id] = agenda.id
    agenda_details[:code] = agenda.code


    agenda_default_user_id = 1

    # I need to set the agenda id in the user email to the new agenda id
    users = docs["Users"]
    users.each_pair do |id,details|
      email = details[:email]
      if email.match(/^\w+-\d+-/)
        email = email.sub(/^(\w+)-\d+-/, "\\1-#{agenda.id}-")
        user = User.find_by(email: email)
        if user.nil?
          user = Agenda.create_agenda_user( agenda, email )
        end
        details[:new_user_id] = user.id
        agenda_default_user_id = user.id if email.match(/coordinator/)
      end
    end


    # ignore AgendaComponentThreads

    docs["AgendaRoles"].each do |details|
      agenda_role = AgendaRole.new
      details.each_pair do |key,value|
        #puts "#{key}: #{value}"
        agenda_role[key] = value unless ['id'].include?(key)
      end
      agenda_role.agenda_id = agenda.id
      agenda_role.save
    end

    # Do the AgendaComponents after I have the new conversation ids

    conversations_details = {}
    conversation_ids = []
    docs["Conversations"].each do |details|
      conversations_details[details['id']] = details
      conversation = Conversation.new
      details.each_pair do |key,value|
        #puts "#{key}: #{value}"
        conversation[key] = value unless ['id','code'].include?(key)
      end
      conversation.user_id =  users[details["user_id"] ][:new_user_id] || agenda_default_user_id
      #puts conversation.inspect
      conversation.save
      details[:new_id] = conversation.id
      details[:new_code] = conversation.code
      conversation_ids.push( conversation.id )
    end

    agenda.update_attribute(:conversation_ids, conversation_ids)


    docs["AgendaComponents"].each do |details|
      agenda_component = AgendaComponent.new
      details.each_pair do |key,value|
        #puts "#{key}: #{value}"
        agenda_component[key] = value unless ['id','code'].include?(key)
      end
      agenda_component.agenda_id = agenda.id

      # update the input data
      details["input"].each_pair do |key,value|
        case key
          when "user_ids"
            new_values = []
            value.each do |id|
              new_values.push( users[id].try{|user|[:new_user_id]} || 1 )
            end
            details["input"]["user_ids"] = new_values

          when "conversation_id"
            details["input"]["conversation_id"] = conversations_details[ value ][:new_id]

          when "conversations_list_ids"
            new_values = []
            value.each do |id|
              new_values.push( conversations_details[id][:new_id] )
            end
            details["input"]["conversations_list_ids"] = new_values

          when "coordinator_user_id"
            details["input"]["coordinator_user_id"] = users[ value ][:new_user_id]

          when "worksheet_conversation_ids"
            new_values = []
            value.each do |id|
              new_values.push( conversations_details[id][:new_id] )
            end
            details["input"]["worksheet_conversation_ids"] = new_values
        end
      end
      agenda_component.input = details["input"]
      agenda_component.save
    end





    votes = {}
    docs["ProConVotes"].each do |v|
      votes[v['comment_id']] = {pro: v["pro_votes"], con: v["con_votes"]}
    end

    #votes.each{|k,v| puts "#{k}: #{v.inspect}"}

    comment_details = {}
    docs["Comments"].each do |details|
      comment_details[details['id']] = details
      # details = comment_details[0]
      #puts details.inspect
      comment = if details['type'] == 'TableComment'
                  TableComment.new
                elsif details['type'] == 'ThemeComment'
                  ThemeComment.new
                elsif details['type'] == 'TitleComment'
                  TitleComment.new
                else
                  Comment.new
                end
      details.each_pair do |key,value|
        #puts "#{key}: #{value}"
        comment[key] = value unless ['id','conversation_id', 'new_id'].include?(key)
      end
      comment.user_id = users[details["user_id"] ][:new_user_id] || agenda_default_user_id
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


    docs["CommentVersions"].each do |details|
      #puts details.inspect
      comment_version = CommentVersion.new
      details.each_pair do |key,value|
        comment_version[key] = value unless ['id'].include?(key)
      end
      comment_version.item_id = comment_details[details["item_id"] ][:new_id]  || 1
      #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
      #puts comment_version.inspect
      comment_version.save
    end

    docs["ThemeVotes"].each do |details|
      #puts details.inspect
      theme_vote = ThemeVote.new
      details.each_pair do |key,value|
        theme_vote[key] = value unless ['id'].include?(key)
      end
      theme_vote.theme_id = comment_details[details["theme_id"] ][:new_id]
      #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
      #puts theme_vote.inspect
      theme_vote.save
    end

    docs["ThemePoints"].each do |details|
      #puts details.inspect
      theme_point = ThemePoint.new
      details.each_pair do |key,value|
        theme_point[key] = value unless ['id'].include?(key)
      end
      theme_point.theme_id = comment_details[details["theme_id"] ][:new_id]
      #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
      #puts theme_point.inspect
      theme_point.save
    end

    # I should restore parked_comments

    docs["CommentThreads"].each do |details|
      #puts details.inspect
      comment_thread = CommentThread.new
      details.each_pair do |key,value|
        comment_thread[key] = value unless ['id'].include?(key)
      end
      comment_thread.child_id = comment_details[details["child_id"] ][:new_id]
      comment_thread.parent_id = comment_details[details["parent_id"] ][:new_id]
      #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
      #puts comment_thread.inspect
      comment_thread.save
    end

    return 'Import completed'

  end

  def self.create_agenda_user(agenda, email)
    o =  [('a'..'z'),('A'..'Z'),(0..9)].map{|x| x.to_a}.flatten
    pw = (0...30).map{ o[rand(o.length)] }.join
    case
      when email.match(/-group-/)
        first_name = "Group"
        role = :scribe
      when email.match(/-themer-/)
        first_name = "Theme team"
        role = :themer
      when email.match(/-coordinator-/)
        first_name = "Coordinator"
        role =:coordinator
      when email.match(/-reporter-/)
        first_name = "Reporter"
        role = :reporter
    end

    role_id = email.match(/(\d+)\@/)[1]
    user = User.new email: email, first_name: first_name, last_name: role_id, password: pw, password_confirmation: pw
    user.skip_confirmation!
    user.save
    Unsubscribe.create email: user.email
    user.add_role role, agenda unless user.has_role? role, agenda
    user
  end

  def reset
    raise "CivicEvolution::AgendaCannotBeReset Not in test mode" unless self.test_mode
    Rails.logger.debug "Reset the data for this Agenda"

    #
    # ParkedComments conversation.id
    # Comments - conversation.id
    #
    # ProConVotes - comment.id
    # CommentVersions comment.id
    # ThemeVotes theme_id (comment.id)
    # ThemePoints theme_id (comment.id)
    # CommentThreads comment.id
    #

    # collect the conversation ids from the component inputs
    conversation_ids = []
    self.agenda_components.each do |c|
      c.input.each_pair do|key,value|
        if key.match(/conversation/)
          conversation_ids << value
        end
      end
    end

    conversation_ids = conversation_ids.flatten.uniq
    comments = Comment.where(type: ['TableComment','ThemeComment'], conversation_id: conversation_ids)
    comment_ids = comments.map(&:id)
    comments.destroy_all
    ParkedComment.where(conversation_id: conversation_ids).destroy_all

    ProConVote.where(comment_id: comment_ids).destroy_all
    ThemeVote.where(theme_id: comment_ids).destroy_all
    ThemePoint.where(theme_id: comment_ids).destroy_all
    CommentThread.where(parent_id: comment_ids).destroy_all
    CommentVersion.where(item_id: comment_ids, item_type: 'Comment').destroy_all
  end


  def self.init_new_agenda(title, description, titles)
    agenda = Agenda.create title: title, description: description

    coordinator = agenda.create_user('coordinator', 1)
    AgendaRole.where(agenda_id: agenda.id, name: 'coordinator', identifier: 1, access_code: 'annie7').first_or_create


    # create the conversations needed for this agenda
    conversations = []
    titles.each_index do |index|
      privacy = {"list"=>"true", "invite"=>"true", "screen"=>"true", "summary"=>"true", "comments"=>"true", "unknown_users"=>"true"}
      conversation = Conversation.create user_id: coordinator.id, starts_at: Time.now + index.hours, privacy: privacy
      title_comment = conversation.build_title_comment user_id: coordinator.id, text: titles[index], order_id: index
      title_comment.post_process_disabled = true
      title_comment.save
      conversations.push( conversation )
    end


    conversations.each{|conversation| coordinator.add_role :coordinator, conversation }
    agenda.update_attribute(:conversation_ids, conversations.map(&:id) )

    reporter = agenda.create_user('reporter', 1)
    conversations.each{|conversation| reporter.add_role :reporter, conversation }
    AgendaRole.where( agenda_id: agenda.id, name: 'reporter', identifier: 1, access_code: 'reporter').first_or_create

    (1..3).each do |i|
      themer = agenda.create_user('themer', i)
      conversations.each{|conversation| themer.add_role :themer, conversation }
      AgendaRole.where( agenda_id: agenda.id, name: 'themer', identifier: i, access_code: "pune").first_or_create
    end

    (1..10).each do |i|
      scribe = agenda.create_user('scribe', i)
      conversations.each{|conversation| scribe.add_role :scribe, conversation }
      AgendaRole.where( agenda_id: agenda.id, name: 'group', identifier: i, access_code: "g#{i}").first_or_create
    end

    agenda
  end


  def create_user(name, index)
    case name
      when "coordinator"
        email_name = "coordinator"
        first_name = "Coordinator"
        role = :coordinator
      when "themer"
        email_name = "themer"
        first_name = "Theme team"
        role = :themer
      when "scribe"
        email_name = "group"
        first_name = "Group"
        role = :scribe
      when "reporter"
        email_name = "reporter"
        first_name = "Reporter"
        role = :reporter

    end
    email = "agenda-#{self.id}-#{email_name}-#{index}@civicevolution.org"
    user = User.find_by(email: email)
    return user unless user.nil?

    o =  [('a'..'z'),('A'..'Z'),(0..9)].map{|x| x.to_a}.flatten
    pw = (0...30).map{ o[rand(o.length)] }.join
    user = User.new email: email, first_name: first_name, last_name: "#{index}", password: pw, password_confirmation: pw
    user.skip_confirmation!
    user.save
    Unsubscribe.create email: user.email

    user.add_role role, self
    user
  end

  def coordinator
    User.find_by("email ~* 'agenda-#{self.id}-coordinator-1'")
  end

  def themers
    User.where("email ~* 'agenda-#{self.id}-themer-'")
  end

  def participants
    User.where("email ~* 'agenda-#{self.id}'").order(:id)
  end

  def conversations
    conversations = Conversation.includes(:title_comment).where(id: self.details["conversation_ids"].flatten)
    ordered_conversations = []
    self.details["conversation_ids"].flatten.each do |id|
      ordered_conversations << conversations.detect{|c| c.id == id}
    end
    ordered_conversations
  end

  def self.agendas
    #Agenda.where(list: true).select('code, title')
    Agenda.where(list: true).map{|a| {code: a.code, title: a.title, munged_title: a.munged_title } }
  end

  def data_set( current_user, link_code )
    Rails.logger.debug "Agenda.data_set with link_code: #{link_code}"

    role, role_id = self.get_role(current_user)

    agenda_details = self.get_details

    link_details = agenda_details["links"][role][link_code]

    raise "CivicEvolution::InvalidLinkCode for role: #{role}, link_code: #{link_code}" if link_details.nil?

    data_set_details = agenda_details["data_sets"][ link_details["data_set"] ]

    # check if there are any parameters that need to be evaluated for their interpolated variables
    data_set_details["parameters"].each_pair do |key,value|
      Rails.logger.debug "value for eval: #{value}"
      data_set_details["parameters"][key] = eval( '"' + value + '"') if value.class.to_s == 'String' && value.match(/#/)
    end
    data_set_details["parameters"]["current_user"] = current_user
    data_set_details["parameters"]["agenda_details"] = agenda_details

    #data_set_details["parameters"].each_pair{|key,value| Rails.logger.debug "#{key}: #{value}" }

    data_set_details["data_class"].constantize.send( data_set_details["data_method"], data_set_details["parameters"] )

  end

  def get_details
    # hardcode the details for development and then create save/retrieve from db

    agenda_details = self.details
    return self.details unless self.details.nil?

    agenda_details = {code: self.code}

    if Rails.env.development?
      # group concurrent conversations in sub arrays
      agenda_details[:conversation_ids] = [[206,207],[208,209,210]]
    else
      # group concurrent conversations in sub arrays
      agenda_details[:conversation_ids] = [[11,12],[13,14,15]]
    end

    conversations = Conversation.includes(:title_comment).where(id: agenda_details[:conversation_ids].flatten)
    ordered_conversations = []
    agenda_details[:conversation_ids].flatten.each do |id|
      ordered_conversations << conversations.detect{|c| c.id == id}
    end

    agenda_details[:conversations] = ordered_conversations.map{|c| {id: c.id, code: c.code, title: c.title, munged_title: c.munged_title } }

    if Rails.env.development?
      agenda_details[:select_conversations] = [208,209,210]
      agenda_details[:allocate_conversations] = [206, 208]
      agenda_details[:allocate_top_themes_conversations] = [208,209,210]

      agenda_details[:theme_map] =
        {
          1=>[357,354,356],
          2=>[355,360,363],
          3=>[359,358,365]
        }
    else
      agenda_details[:select_conversations] = [13,14,15]
      agenda_details[:allocate_conversations] = [11, 13]
      agenda_details[:allocate_top_themes_conversations] = [13,14,15]

      agenda_details[:theme_map] =
          {
              1=>[65, 62, 64],
              2=>[63, 68, 71],
              3=>[67, 66, 73]
          }
    end

    agenda_details[:coordinator_user_id] = self.coordinator.id

    agenda_details[:links] = {
      coordinator: {},
      themer:{},
      group: {},
      reporter: {},
      public: {}
    }

    agenda_details[:data_sets] = {}
    agenda_details[:links][:lookup] = {}
    agenda_details[:conversations].each_index do |conv_index|
      conversation = agenda_details[:conversations][conv_index]

      # link for display final themes
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
        title: %Q|Display final themes for "#{conversation[:title]}"|,
        link_code:  link_code,
        href: "/#/agenda/#{self.code}-#{link_code}/theme-results/#{conversation[:munged_title]}",
        conversation_code: "#{conversation[:code]}",
        data_set: "conversation-final-themes",
        disabled: false,
        role: 'reporter'
      }
      agenda_details[:links][:reporter][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "reporter"

      # link for theme small group deliberation
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Theme groups for "#{conversation[:title]}"|,
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/sgd-theme/#{conversation[:munged_title]}",
          conversation_code: "#{conversation[:code]}",
          data_set: "theme-small-group",
          disabled: false,
          role: 'themer'
      }
      agenda_details[:links][:themer][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "themer"

      # link for coordinator theming
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Coordinator theming for "#{conversation[:title]}"|,
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/coord-theme/#{conversation[:munged_title]}",
          conversation_code: "#{conversation[:code]}",
          data_set: "coordinator-theming",
          disabled: false,
          role: 'coordinator'
      }
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "coordinator"

      # link for group scribe
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Deliberate on "#{conversation[:title]}"|,
          id: conversation[:id],
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/sgd/#{conversation[:munged_title]}",
          conversation_code: "#{conversation[:code]}",
          data_set: "small-group-deliberation",
          disabled: false,
          role: 'group',
          type: 'deliberate'
      }
      agenda_details[:links][:group][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "group"


      if agenda_details[:select_conversations].include?( conversation[:id] )
        # link for group scribe select
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Select favorites ideas for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/select/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "themes-select",
            disabled: false,
            role: 'group',
            type: 'select'
        }
        agenda_details[:links][:group][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "group"

        # link for select results
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Display Select Results for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/select-results/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "conversation-themes-select-results",
            disabled: false,
            role: 'reporter',
            type: 'select-results'
        }
        agenda_details[:links][:reporter][ link_code ] = link
        agenda_details[:links][:coordinator][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "reporter"
      end


      if agenda_details[:allocate_conversations].include?( conversation[:id] )
        # link for group scribe allocate
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Allocate points for ideas for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/allocate/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "themes-allocate",
            disabled: false,
            role: 'group',
            type: 'select'
        }
        agenda_details[:links][:group][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "group"

        # link for allocate results
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Display allocate results for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/allocate-results/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "conversation-themes-allocate-results",
            disabled: false,
            role: 'reporter',
            type: 'allocate-results'
        }
        agenda_details[:links][:reporter][ link_code ] = link
        agenda_details[:links][:coordinator][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "reporter"
      end
    end

    if agenda_details[:allocate_top_themes_conversations] && agenda_details[:allocate_top_themes_conversations].size > 0
      # link for allocate top ideas from 3 conversations
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: "Prioritise the top ideas",
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/allocate/prioritise-top-ideas",
          data_set: "collected-themes-allocation",
          page_title: 'Prioritise the top ideas',
          disabled: false,
          role: 'group',
          type: 'select'
      }
      agenda_details[:links][:group][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "group"

      # link for allocate results for top ideas from 3 conversations
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Display allocate results for Top Ideas|,
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/allocate-results/prioritise-top-ideas-results",
          data_set: "collected-themes-allocation-results",
          page_title: 'Prioritisation results for top ideas',
          disabled: false,
          role: 'reporter',
          type: 'allocate-results'
      }
      agenda_details[:links][:reporter][ link_code ] = link
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "reporter"
    end

    # link for report-generator
    link_code = self.create_link_code( agenda_details[:links][:lookup] )
    link = {
        title: "Report generator",
        href: "/#/agenda/#{agenda_details[:code]}/report-generator/#{self.munged_title}",

        disabled: false,
        role: 'reporter',
    }
    agenda_details[:links][:reporter][ link_code ] = link
    agenda_details[:links][:coordinator][ link_code ] = link
    agenda_details[:links][:lookup][link_code] = "reporter"

    agenda_details[:data_sets]["conversation-final-themes"] =
        {
            data_class: "ThemeSmallGroupTheme",
            data_method: "data_key_themes_with_examples",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: agenda_details[:coordinator_user_id]
            }
        }

    agenda_details[:data_sets]["theme-small-group"] =
        {
            data_class: "ThemeSmallGroupDeliberation",
            data_method: "data_theme_small_groups_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                group_user_ids: '#{agenda_details["theme_map"][role_id]}'
            }
        }

    agenda_details[:data_sets]["coordinator-theming"] =
        {
            data_class: "ThemeSmallGroupTheme",
            data_method: "data_coordinator_theming_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: agenda_details[:coordinator_user_id]
            }
        }

    agenda_details[:data_sets]["small-group-deliberation"] =
        {
            data_class: "SmallGroupDeliberation",
            data_method: "data_small_group_deliberation_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}'
            }
        }

    agenda_details[:data_sets]["themes-select"] =
        {
            data_class: "ThemeSelection",
            data_method: "data_themes_select_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: agenda_details[:coordinator_user_id]
            }
        }

    agenda_details[:data_sets]["conversation-themes-select-results"] =
        {
            data_class: "ThemeSelection",
            data_method: "data_themes_select_results",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: agenda_details[:coordinator_user_id]
            }
        }

    agenda_details[:data_sets]["themes-allocate"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_themes_allocate_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: agenda_details[:coordinator_user_id]
            }
        }

    agenda_details[:data_sets]["conversation-themes-allocate-results"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_themes_allocation_results",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: agenda_details[:coordinator_user_id]
            }
        }

    agenda_details[:data_sets]["collected-themes-allocation"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_collected_themes_allocation_page_data",
            parameters: {
                conversation_ids: "#{agenda_details[:allocate_top_themes_conversations]}",
                top_themes_count: 3,
                coordinator_user_id: agenda_details[:coordinator_user_id],
                page_title: '#{link_details["page_title"]}'
            }
        }

    agenda_details[:data_sets]["collected-themes-allocation-results"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_collected_themes_allocation_results",
            parameters: {
                conversation_ids: "#{agenda_details[:allocate_top_themes_conversations]}",
                top_themes_count: 3,
                coordinator_user_id: agenda_details[:coordinator_user_id],
                page_title: '#{link_details["page_title"]}'
            },
            data_set_title: 'Top ideas',
            report_generator_list: true
        }


    self.update_attribute(:details, agenda_details)
    self.details
  end

  def create_link_code(codes_hash)
    begin
      code = (0..2).map{ ('a'..'z').to_a[rand(26)] }.join
    end while codes_hash[code]
    code  # return a code that is not used yet
  end

  def get_role(current_user)
    match = current_user.try{|user| user.email.match(/agenda-#{self.id}-(\w*)-(\d+)/)}
    if match
      return match[1], match[2]
    else
      return nil, nil
    end

  end

  def report_data_sets
    # return data_sets to be included in the report generator
    data_sets = []
    self.details["data_sets"].each_pair do |key, data_set|
      if data_set["report_generator_list"]
        data_sets.push( {title: data_set["data_set_title"], key: "#{self.code}-#{key}" } )
      end
    end
    data_sets
  end

end
