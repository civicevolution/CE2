class Agenda < ActiveRecord::Base
  attr_accessible :title, :description, :code, :access_code, :template_name, :list, :status
  has_many :agenda_roles
  has_many :agenda_activities
  has_many :agenda_components
  has_many :agenda_component_threads

  has_many :mca, class_name: 'MultiCriteriaAnalysis', foreign_key: :agenda_id

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
    agenda_details = self.details
    menu_data = []

    # get the role for this user
    role, role_id = self.get_role(current_user)
    if role
      # use agenda_details to construct the menu_data
      agenda_details["links"][role].each_value do |link|
        menu_data.push( {link_code: link["link_code"], title: link["title"], href: link["href"], group_id: link["id"]})
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
          theme[:text] = theme[:text].split(/\n/)[0]
        end
      when 'allocation-results'
        data = ThemeAllocation.data_themes_allocation_results({"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id})
        data[:allocated_themes].each do|theme|
          theme[:count] = "#{theme[:points]}pts"
          theme[:text] = theme[:text].split(/\n/)[0]
        end

      when 'select-worksheet'
        data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id} )
        data[:themes].each do |theme|
          #theme[:text] = theme[:text].gsub(/\[quote.*\/quote\]/m,'')
          theme[:text] = theme[:text].split(/\n/)[0]
        end
        data = {title: data[:title], worksheet_themes: data[:themes]}

      when 'allocation-worksheet'
        data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => conversation_code, "coordinator_user_id" => coordinator_user_id} )
        data[:themes].each do |theme|
          #theme[:text] = theme[:text].gsub(/\[quote.*\/quote\]/m,'')
          theme[:text] = theme[:text].split(/\n/)[0]
        end
        data = {title: data[:title], worksheet_themes: data[:themes]}

      when 'recommendation-results'
        data = ConversationRecommendation.data_recommendation_results({"conversation_code" => conversation_code})
        data[:allocated_themes] = data[:recommendation_options]
        data[:allocated_themes].each do|theme|
          theme[:count] = "(#{theme[:votes]})"
          theme[:text] = theme[:text].split(/\n/)[0]
        end

    end
    data
  end

  def export_to_file(file)
    # This writes all of the data to the file and to be sent to the browser

    file.write( {"Agenda" => self.attributes}.to_yaml )

    agenda_roles = self.agenda_roles
    file.write( {"AgendaRoles" => agenda_roles.map{|c| c.attributes}}.to_yaml )

    conversations = Conversation.where(id: self.conversation_ids.flatten.uniq)

    file.write( {"Conversations" => conversations.map{|c| c.attributes}}.to_yaml )

    comments = []
    conversations.each do |c|
      comments.concat c.comments
    end

    file.write( {"Comments" => comments.map{|c| c.attributes}}.to_yaml )

    comment_ids = comments.map(&:id)

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

    recommendation_votes = RecommendationVote.where(conversation_id: conversations.map(&:id))
    file.write( {"RecommendationVotes" => recommendation_votes.map{|rv| rv.attributes}}.to_yaml )

    # I should get parked_comments

    user_recs = {}
    self.participants.sort_by{|first_name, last_name| [first_name, last_name]}.each do |u|
      user_recs[u.id] = {email: u.email, first_name: u.first_name, last_name: u.last_name}
    end
    file.write( {"Users" => user_recs}.to_yaml )



    mca_tables = MultiCriteriaAnalysis.where(agenda_id: self.id)
    file.write( {"MultiCriteriaAnalyses" => mca_tables.map{|c| c.attributes}}.to_yaml )

    mca_criteria = []
    mca_options = []
    mca_tables.each do |mca|
      mca_criteria.concat mca.criteria
      mca_options.concat mca.options
    end

    file.write( {"McaCriteria" => mca_criteria.map{|c| c.attributes}}.to_yaml )
    file.write( {"McaOptions" => mca_options.map{|c| c.attributes}}.to_yaml )

    option_ids = mca_options.map(&:id)
    mca_evaluations = McaOptionEvaluation.where(mca_option_id: option_ids)
    file.write( {"McaOptionEvaluations" => mca_evaluations.map{|c| c.attributes}}.to_yaml )

    evaluation_ids = mca_evaluations.map(&:id)
    mca_ratings = McaRating.where(mca_option_evaluation_id: evaluation_ids)
    file.write( {"McaRatings" => mca_ratings.map{|c| c.attributes}}.to_yaml )


    #mca = MultiCriteriaAnalysis.find_by(agenda_id: self.id)
    #if mca
    #  file.write( {"MultiCriteriaAnalysis" => mca.attributes}.to_yaml )
    #
    #  file.write( {"McaCriteria" => mca.criteria.map{|c| c.attributes}}.to_yaml )
    #
    #  file.write( {"McaOptions" => mca.options.map{|c| c.attributes}}.to_yaml )
    #
    #  mca_evaluations = []
    #  mca.options.each do |option|
    #    mca_evaluations.push option.evaluations.map{|c| c.attributes}
    #  end
    #  file.write( {"McaEvaluations" => mca_evaluations.flatten}.to_yaml )
    #
    #
    #  mca_ratings = []
    #  mca.criteria.each do |criteria|
    #    mca_ratings.push criteria.ratings.map{|c| c.attributes}
    #  end
    #  file.write( {"McaRatings" => mca_ratings.flatten}.to_yaml )
    #end

  end

  def self.import(file)
    agenda = nil
    ActiveRecord::Base.transaction do

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
      agenda_details['details'][:code] = agenda.code

      agenda.update_attribute(:title, "IMP(#{agenda.id}) #{agenda.title}")
      agenda.update_attribute(:list, true)

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
          details[:new_id] = user.id
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

      agenda_details['details'][:coordinator_user_id] = agenda_default_user_id

      details_arrays = %w(conversation_ids select_conversations allocate_conversations allocate_top_themes_conversations make_recommendation allocate_multiple_conversations themes_only)
      details_arrays.each do |name|
        agenda_details['details'][name] = Agenda.update_record_ids(conversations_details, agenda_details['details'][name])
      end

      agenda_details['details']['theme_map'].each_pair do |key, value|
        agenda_details['details']['theme_map'][key] = Agenda.update_record_ids(users, value)
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

      if docs["RecommendationVotes"]
        docs["RecommendationVotes"].each do |details|
          #puts details.inspect
          recommendation_vote = RecommendationVote.new
          details.each_pair do |key,value|
            recommendation_vote[key] = value unless ['id'].include?(key)
          end
          recommendation_vote.conversation_id = conversations_details[details["conversation_id"] ][:new_id]
          #puts recommendation_vote.inspect
          recommendation_vote.save
        end
      end

      # I should restore parked_comments

      docs["CommentThreads"].each do |details|
        #puts details.inspect
        comment_thread = CommentThread.new
        details.each_pair do |key,value|
          comment_thread[key] = value unless ['id'].include?(key)
        end
        comment_thread.child_id = comment_details[details["child_id"] ][:new_id] unless !comment_details[details["child_id"] ]
        comment_thread.parent_id = comment_details[details["parent_id"] ][:new_id] unless !comment_details[details["parent_id"] ]
        #Rails.logger.debug "get votes for details['id']: #{details['id']}, votes[ details['id']]: #{votes[ details['id']]}"
        #puts comment_thread.inspect
        comment_thread.save
      end

      # add_roles to the conversations for AUTH
      conversations = Conversation.where(id: conversation_ids)
      conversations.each do |conversation|
        agenda.participants.each do |participant|
          role = participant.email.match(/agenda-\d+-(\w+)-/)[1]
          if role == 'group'
            role = :scribe
          else
            role = role.to_sym
          end
          puts role
          participant.add_role role, conversation
        end
      end

      # Import the mca stuff

      mca_details = {}
      docs["MultiCriteriaAnalyses"].each do |details|
        mca_details[details['id']] = details
        mca = MultiCriteriaAnalysis.new
        details.each_pair do |key,value|
          #puts "#{key}: #{value}"
          mca[key] = value unless ['id','code'].include?(key)
        end
        mca.agenda_id = agenda.id
        puts mca.inspect
        mca.save
        details[:new_id] = mca.id
      end

      criteria_details = {}
      docs["McaCriteria"].each do |details|
        criteria_details[details['id']] = details
        criteria = McaCriteria.new
        details.each_pair do |key,value|
          #puts "#{key}: #{value}"
          criteria[key] = value unless ['id','code','multi_criteria_analysis_id'].include?(key)
        end
        criteria.multi_criteria_analysis_id = mca_details[details['multi_criteria_analysis_id']][:new_id]
        #puts criteria.inspect
        criteria.save
        details[:new_id] = criteria.id
      end

      options_details = {}
      docs["McaOptions"].each do |details|
        options_details[details['id']] = details
        option = McaOption.new
        details.each_pair do |key,value|
          #puts "#{key}: #{value}"
          option[key] = value unless ['id','code','multi_criteria_analysis_id'].include?(key)
        end
        option.multi_criteria_analysis_id = mca_details[details['multi_criteria_analysis_id']][:new_id]
        #puts option.inspect
        option.save
        details[:new_id] = option.id
      end

      evaluation_details = {}
      docs["McaOptionEvaluations"].each do |details|
        evaluation_details[details['id']] = details
        evaluation = McaOptionEvaluation.new
        details.each_pair do |key,value|
          #puts "#{key}: #{value}"
          evaluation[key] = value unless ['id','new_id','mca_option_id','user_id'].include?(key)
        end
        evaluation.mca_option_id = options_details[details["mca_option_id"]][:new_id]
        evaluation.user_id = users[details["user_id"] ][:new_user_id] || agenda_default_user_id
        evaluation.save
        details[:new_id] = evaluation.id
      end

      evaluation_rating_details = {}
      docs["McaRatings"].each do |details|
        evaluation_rating_details[details['id']] = details
        evaluation_rating = McaRating.new
        details.each_pair do |key,value|
          #puts "#{key}: #{value}"
          evaluation_rating[key] = value unless ['id','new_id', 'mca_criteria_id', 'mca_option_evaluation_id'].include?(key)
        end
        evaluation_rating.mca_option_evaluation_id = evaluation_details[details["mca_option_evaluation_id"]][:new_id]
        evaluation_rating.mca_criteria_id = criteria_details[details["mca_criteria_id"] ][:new_id]
        evaluation_rating.post_process_disabled = true
        evaluation_rating.save
        details[:new_id] = evaluation_rating.id
      end

      details_arrays = %w(mca_ids mca_id_plenary mca_ids_coord_only)
      details_arrays.each do |name|
        agenda_details['details'][name] = Agenda.update_record_ids(mca_details, agenda_details['details'][name])
      end

      agenda.update_attribute(:details, agenda_details['details'])
      #agenda.refresh_agenda_details_links_and_data_sets
    end
    agenda.refresh_agenda_details_links_and_data_sets
    return agenda.code
  end

  def self.update_record_ids(translation_details, ids_array)
    return if ids_array.nil?
    ids_array.each_index do |ind|
      if ids_array[ind].class == Array
        ids_array[ind] = update_record_ids(translation_details, ids_array[ind])
      else
        ids_array[ind] = translation_details[ ids_array[ind] ][:new_id]
      end
    end
    ids_array
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

    conversation_ids = self.conversation_ids.flatten.uniq
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

  def delete_agenda
    raise "CivicEvolution::AgendaCannotBeDeleted UNLESS in test mode" unless self.test_mode
    raise "CivicEvolution::AgendaCannotBeDeleted in PROD" unless Rails.env.development?
    Rails.logger.debug "Delete this Agenda"

    conversation_ids = self.conversation_ids.flatten.uniq
    comments = Comment.where(type: ['TableComment','ThemeComment'], conversation_id: conversation_ids)
    comment_ids = comments.map(&:id)
    comments.destroy_all
    ParkedComment.where(conversation_id: conversation_ids).destroy_all

    ProConVote.where(comment_id: comment_ids).destroy_all
    ThemeVote.where(theme_id: comment_ids).destroy_all
    ThemePoint.where(theme_id: comment_ids).destroy_all
    CommentThread.where(parent_id: comment_ids).destroy_all
    CommentVersion.where(item_id: comment_ids, item_type: 'Comment').destroy_all

    # destroy the mca stuff
    MultiCriteriaAnalysis.delete_mca( self.mca.map(&:id) )

    Conversation.where(id: conversation_ids ).destroy_all
    self.agenda_roles.destroy_all
    self.participants.destroy_all
    self.destroy
  end


  def self.init_new_agenda(title, description, titles)
    agenda = Agenda.create title: title, description: description

    coordinator = agenda.create_user('coordinator', 1)
    coordinator.add_role :coordinator, agenda
    AgendaRole.where(agenda_id: agenda.id, name: 'coordinator', identifier: 1, access_code: 'coord7').first_or_create


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
    reporter.add_role :reporter, agenda
    AgendaRole.where( agenda_id: agenda.id, name: 'reporter', identifier: 1, access_code: 'reporter').first_or_create

    (1..3).each do |i|
      themer = agenda.create_user('themer', i)
      conversations.each{|conversation| themer.add_role :themer, conversation }
      themer.add_role :themer, agenda
      AgendaRole.where( agenda_id: agenda.id, name: 'themer', identifier: i, access_code: "gpb").first_or_create
    end

    (1..10).each do |i|
      scribe = agenda.create_user('scribe', i)
      conversations.each{|conversation| scribe.add_role :scribe, conversation }
      scribe.add_role :scribe, agenda
      AgendaRole.where( agenda_id: agenda.id, name: 'group', identifier: i, access_code: "g#{i}").first_or_create
    end

    agenda
  end


  def self.add_conversations_to_agenda(code, titles)
    titles = [ titles ] unless titles.class == Array

    agenda = Agenda.find_by(code: code)
    coordinator = agenda.coordinator
    # create the new conversation(s) needed for this agenda
    conversations = []
    titles.each_index do |index|
      privacy = {"list"=>"true", "invite"=>"true", "screen"=>"true", "summary"=>"true", "comments"=>"true", "unknown_users"=>"true"}
      conversation = Conversation.create user_id: coordinator.id, starts_at: Time.now + index.hours, privacy: privacy
      title_comment = conversation.build_title_comment user_id: coordinator.id, text: titles[index], order_id: index
      title_comment.post_process_disabled = true
      title_comment.save
      conversations.push( conversation )
    end

    conversations.each do |conversation|
      agenda.participants.each do |participant|
        role = participant.email.match(/agenda-\d+-(\w+)-/)[1]
        if role == 'group'
          role = :scribe
        else
          role = role.to_sym
        end
        puts role
        participant.add_role role, conversation
      end
    end

    conversation_ids = agenda.conversation_ids << conversations.map(&:id)
    agenda.update_attribute(:conversation_ids, conversation_ids.flatten )
    agenda.refresh_agenda_details_links_and_data_sets
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
    ordered_conversations.map{|c| {id: c.id, code: c.code, title: c.title, munged_title: c.munged_title } }
  end

  def self.agendas
    #Agenda.where(list: true).select('code, title')
    Agenda.where(list: true).order(:id).map{|a| {code: a.code, title: a.title, munged_title: a.munged_title } }
  end

  def data_set( current_user, link_code )
    Rails.logger.debug "Agenda.data_set with link_code: #{link_code}"

    role, role_id = self.get_role(current_user)

    agenda_details = self.details

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

  def reset_details_ids
    # hardcode the details for development and then create save/retrieve from db
    self.update_attribute(:details, {})
    agenda_details = {
      code: self.code,
      coordinator_user_id: self.coordinator.id
    }

    if Rails.env.development?
      # group concurrent conversations in sub arrays
      #agenda_details[:conversation_ids] = [[206,207],[208,209,210]]
      #agenda_details[:conversation_ids] = [211, 212, 213, 214, 215, 216]
      agenda_details[:conversation_ids] = [402, [404, 405, 406],407]
    else
      # group concurrent conversations in sub arrays
      agenda_details[:conversation_ids] = [14, [16, 17, 18], [19, 20, 21, 22]]
    end

    if Rails.env.development?
      agenda_details[:select_conversations] = []
      agenda_details[:allocate_conversations] = [402]
      #agenda_details[:allocate_top_themes_conversations] = [213, 214]
      agenda_details[:allocate_multiple_conversations] = []
      agenda_details[:themes_only] = []
      agenda_details[:make_recommendation] = []
      agenda_details[:theme_map] =
          {
              1=>[1033, 1034, 1035, 1036],
              2=>[1037,1038, 1039, 1040],
              3=>[1033, 1034, 1035, 1036, 1037,1038, 1039, 1040]
          }

      agenda_details[:mca_ids] = [48, 49]
      agenda_details[:mca_id_plenary] = [48]
      agenda_details[:mca_ids_coord_only] = []

    else
      agenda_details[:select_conversations] = []
      agenda_details[:allocate_conversations] = [14]
      agenda_details[:allocate_top_themes_conversations] = []
      agenda_details[:allocate_multiple_conversations] = []
      agenda_details[:themes_only] = []
      agenda_details[:make_recommendation] = []
      agenda_details[:theme_map] =
          {
              1=>[37, 38, 39, 40],
              2=>[41, 42, 43, 44],
              3=>[37, 38, 39, 40, 41, 42, 43, 44]
          }
      agenda_details[:mca_ids] = [2, 3]
      agenda_details[:mca_id_plenary] = [2]
      agenda_details[:mca_ids_coord_only] = []

    end
    self.update_attribute(:details, agenda_details)
  end

  def refresh_agenda_details_links_and_data_sets

    agenda_details = self.details.symbolize_keys

    # reset the links and data sets
    agenda_details[:data_sets] = {}
    agenda_details[:links] = {
        coordinator: {},
        themer:{},
        group: {},
        reporter: {},
        public: {},
        lookup: {}
    }

    conversations = Conversation.includes(:title_comment).where(id: agenda_details[:conversation_ids].flatten)
    ordered_conversations = []
    agenda_details[:conversation_ids].flatten.each do |id|
      ordered_conversations << conversations.detect{|c| c.id == id}
    end
    conversations = ordered_conversations.map{|c| {id: c.id, code: c.code, title: c.title, munged_title: c.munged_title } }

    conversations.each_index do |conv_index|
      conversation = conversations[conv_index]



      if agenda_details[:make_recommendation] && agenda_details[:make_recommendation].include?( conversation[:id] )
        # link for group scribe select
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Make recommendation for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/recommend-count/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "conversation-recommend",
            disabled: false,
            role: 'group',
            type: 'select'
        }
        agenda_details[:links][:group][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "group"

        # link for select results
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Display recommendation results for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/recommendation-results/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "conversation-recommendation-results",
            disabled: false,
            role: 'reporter',
            type: 'select-results'
        }
        agenda_details[:links][:reporter][ link_code ] = link
        agenda_details[:links][:coordinator][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "reporter"
      end




      if !agenda_details[:themes_only].include?( conversation[:id] )
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

        # link for theme small group deliberation
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Theme groups for "#{conversation[:title]}"|,
            id: conversation[:id],
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/sgd-theme/#{conversation[:munged_title]}",
            conversation_code: "#{conversation[:code]}",
            data_set: "theme-small-group",
            disabled: false,
            role: 'themer'
        }
        agenda_details[:links][:themer][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "themer"
      end

      # link for coordinator theming
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Coordinator theming for "#{conversation[:title]}"|,
          id: conversation[:id],
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/coord-theme/#{conversation[:munged_title]}",
          conversation_code: "#{conversation[:code]}",
          data_set: "coordinator-theming",
          disabled: false,
          role: 'coordinator'
      }
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "coordinator"

      # link for live-editing
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Live editing for "#{conversation[:title]}"|,
          id: conversation[:id],
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/live-edit/#{conversation[:munged_title]}",
          conversation_code: "#{conversation[:code]}",
          data_set: "coordinator-theming",
          disabled: false,
          role: 'coordinator'
      }
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "coordinator"

      # link for display final themes
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Display final themes for "#{conversation[:title]}"|,
          id: conversation[:id],
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/theme-results/#{conversation[:munged_title]}",
          conversation_code: "#{conversation[:code]}",
          data_set: "conversation-final-themes",
          disabled: false,
          role: 'reporter'
      }
      agenda_details[:links][:reporter][ link_code ] = link
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "reporter"

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
          data_set: "collected-top-themes-allocation",
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
          data_set: "collected-top-themes-allocation-results",
          page_title: 'Prioritisation results for top ideas',
          disabled: false,
          role: 'reporter',
          type: 'allocate-results'
      }
      agenda_details[:links][:reporter][ link_code ] = link
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "reporter"
    end

    if agenda_details[:allocate_multiple_conversations] && agenda_details[:allocate_multiple_conversations].size > 0
      # link for allocate ideas from multiple deliberations
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: "Prioritise combined ideas",
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/allocate/prioritise-top-ideas",
          data_set: "collected-themes-allocation",
          page_title: 'Prioritise the combined ideas',
          disabled: false,
          role: 'group',
          type: 'select'
      }
      agenda_details[:links][:group][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "group"

      # link for allocate results for top ideas from 3 conversations
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|Display allocate results for Combined Ideas|,
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/allocate-results/prioritise-top-ideas-results",
          data_set: "collected-themes-allocation-results",
          page_title: 'Prioritisation results for combined ideas',
          disabled: false,
          role: 'reporter',
          type: 'allocate-results'
      }
      agenda_details[:links][:reporter][ link_code ] = link
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "reporter"
    end

    if agenda_details[:mca_id_plenary] && agenda_details[:mca_id_plenary].size > 0
      # link for coord-mca-table
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: "Plenary Assessment Exercise",
          id: 'mca',
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/coord-mca-table/#{self.munged_title}",
          data_set: "coord-multi-criteria-analysis-table",
          mode: 'plenary',
          mca_id: agenda_details[:mca_id_plenary][0],
          page_title: 'Plenary: Multi Criteria Analysis Results for Infrastructure Projects',
          disabled: false,
          role: 'coordinator',
      }
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "coordinator"

      # link for group-mca-table
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: "Plenary Assessment Exercise",
          id: 'mca',
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/group-mca-table/#{self.munged_title}",
          data_set: "group-multi-criteria-analysis-table",
          mode: 'plenary',
          mca_id: agenda_details[:mca_id_plenary][0],
          page_title: 'Plenary: Group input for Multi Criteria Analysis for Infrastructure Projects',
          disabled: false,
          role: 'group',
      }
      agenda_details[:links][:group][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "group"
    end


    # Add links for MCA

    mcas = MultiCriteriaAnalysis.where(id: agenda_details[:mca_ids])
    ordered_mcas = []
    agenda_details[:mca_ids].each do |id|
      ordered_mcas << mcas.detect{|c| c.id == id}
    end

    ordered_mcas.each_index do |ind|
      mca = ordered_mcas[ind]

      # link for coord-mca-table
      link_code = self.create_link_code( agenda_details[:links][:lookup] )
      link = {
          title: %Q|MCA Evaluation results for #{mca.title}|,
          id: 'mca',
          link_code:  link_code,
          href: "/#/agenda/#{self.code}-#{link_code}/coord-mca-table/#{self.munged_title}",
          data_set: "coord-multi-criteria-analysis-table",
          mode: 'projects',
          mca_id: mca.id,
          page_title: "Multi Criteria Analysis Results for #{mca.title}",
          disabled: false,
          role: 'coordinator',
      }
      agenda_details[:links][:coordinator][ link_code ] = link
      agenda_details[:links][:lookup][link_code] = "coordinator"

      if !agenda_details[:mca_ids_coord_only].include?( mca.id )
        # link for group-mca-table
        link_code = self.create_link_code( agenda_details[:links][:lookup] )
        link = {
            title: %Q|Evaluate #{mca.title}|,
            id: 'mca',
            link_code:  link_code,
            href: "/#/agenda/#{self.code}-#{link_code}/group-mca-table/#{self.munged_title}",
            data_set: "group-multi-criteria-analysis-table",
            mode: 'projects',
            mca_id: mca.id,
            page_title: "Group input for Multi Criteria Analysis for #{mca.title}",
            disabled: false,
            role: 'group',
        }
        agenda_details[:links][:group][ link_code ] = link
        agenda_details[:links][:lookup][link_code] = "group"
      end
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
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}'
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
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}'
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
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}'
            }
        }

    agenda_details[:data_sets]["conversation-themes-select-results"] =
        {
            data_class: "ThemeSelection",
            data_method: "data_themes_select_results",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}'
            }
        }

    agenda_details[:data_sets]["conversation-recommend"] =
        {
            data_class: "ConversationRecommendation",
            data_method: "data_recommend_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}'
            }
        }

    agenda_details[:data_sets]["conversation-recommendation-results"] =
        {
            data_class: "ConversationRecommendation",
            data_method: "data_recommendation_results",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}'
            }
        }

    agenda_details[:data_sets]["themes-allocate"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_themes_allocate_page_data",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}'
            }
        }

    agenda_details[:data_sets]["conversation-themes-allocate-results"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_themes_allocation_results",
            parameters: {
                conversation_code: '#{link_details["conversation_code"]}',
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}'
            }
        }

    agenda_details[:data_sets]["collected-top-themes-allocation"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_collected_themes_allocation_page_data",
            parameters: {
                conversation_ids: '#{agenda_details["allocate_top_themes_conversations"]}',
                top_themes_count: 3,
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}',
                page_title: '#{link_details["page_title"]}'
            }
        }

    agenda_details[:data_sets]["collected-top-themes-allocation-results"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_collected_themes_allocation_results",
            parameters: {
                conversation_ids: '#{agenda_details["allocate_top_themes_conversations"]}',
                top_themes_count: 3,
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}',
                page_title: '#{link_details["page_title"]}'
            },
            data_set_title: 'Top ideas',
            report_generator_list: (agenda_details[:allocate_top_themes_conversations] && agenda_details[:allocate_top_themes_conversations].size > 0)
        }

    agenda_details[:data_sets]["collected-themes-allocation"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_collected_themes_allocation_page_data",
            parameters: {
                conversation_ids: '#{agenda_details["allocate_multiple_conversations"]}',
                randomized_theme_ids: '#{agenda_details["allocate_multiple_conversations_theme_ids"]}',
                top_themes_count: 1000,
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}',
                page_title: '#{link_details["page_title"]}'
            }
        }

    agenda_details[:data_sets]["collected-themes-allocation-results"] =
        {
            data_class: "ThemeAllocation",
            data_method: "data_collected_themes_allocation_results",
            parameters: {
                conversation_ids: '#{agenda_details["allocate_multiple_conversations"]}',
                randomized_theme_ids: '#{agenda_details["allocate_multiple_conversations_theme_ids"]}',
                top_themes_count: 1000,
                coordinator_user_id: '#{agenda_details["coordinator_user_id"]}',
                page_title: '#{link_details["page_title"]}'
            },
            data_set_title: 'Combined ideas',
            report_generator_list: (agenda_details[:allocate_multiple_conversations] && agenda_details[:allocate_multiple_conversations].size > 0)
        }

    agenda_details[:data_sets]["coord-multi-criteria-analysis-table"] =
        {
            data_class: "MultiCriteriaAnalysis",
            data_method: "coord_evaluation_data",
            parameters: {
                mode: '#{link_details["mode"]}',
                mca_id: '#{link_details["mca_id"]}',
                page_title: '#{link_details["page_title"]}'
            }
        }

    agenda_details[:data_sets]["group-multi-criteria-analysis-table"] =
        {
            data_class: "MultiCriteriaAnalysis",
            data_method: "group_evaluation_data",
            parameters: {
                mode: '#{link_details["mode"]}',
                mca_id: '#{link_details["mca_id"]}',
                page_title: '#{link_details["page_title"]}'
            }
        }

    self.update_attribute(:details, agenda_details)
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


  def self.display_details(code)
    agenda = Agenda.find_by(code: code)
    details = %w(coordinator_user_id conversation_ids select_conversations allocate_conversations allocate_top_themes_conversations allocate_multiple_conversations themes_only make_recommendation mca_ids mca_id_plenary mca_ids_coord_only theme_map)
    puts "Agenda details:"
    puts "Title: #{agenda.title}"
    puts "code: #{agenda.code}"
    puts "raw conversation_ids: #{agenda.conversation_ids}"
    details.each do |name|
      puts "#{name}: #{agenda.details[name]}"
    end
    ""
  end

  def self.adjust_details(code, key, value, rebuild_flag = false)
    agenda = Agenda.find_by(code: code)

    agenda_details = agenda.details.symbolize_keys
    agenda_details[key.to_sym] = value

    agenda.update_attribute(:details, agenda_details)

    agenda.refresh_agenda_details_links_and_data_sets if rebuild_flag
    "updated agenda.details[#{key.to_sym}] = #{value}\n"
    Agenda.display_details(code)
  end

end
