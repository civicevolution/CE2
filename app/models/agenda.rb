class Agenda < ActiveRecord::Base
  attr_accessible :title, :description, :code, :access_code, :template_name, :list, :status
  has_many :agenda_roles
  has_many :agenda_activities
  has_many :agenda_components
  has_many :agenda_component_threads

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
    # get the role for this user
    if current_user.nil?
      menu_data = []
    else
      role = current_user.email.match(/agenda-\d+-(\w+)-\d/).try{ |matches| matches[1] } || ''
      role_relevant_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, role).order(:starts_at)
      menu_data = role_relevant_components.map{|c| c.menu_details(role, current_user.email)}.compact
    end

    details = {
        title: self.title,
        munged_title: self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50],
        description: self.description,
        code: self.code,
        template_name: template_name,
        menu_data: menu_data
    }
  end

  def role_menu_data(current_user)
    # get the role for this user
    role = current_user.email.match(/agenda-\d+-(\w+)-\d/)[1]
    role_relevant_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, role).order(:ends_at)
    menu_data = role_relevant_components.map{|c| c.menu_details(role, current_user.email)}.compact
  end

  def munged_title
    self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]
  end

  def participant_report
    participant_report_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, 'participant_report').order(:starts_at)
    participant_report_components.map(&:participant_report_details)
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

    user_ids.concat theme_votes.map(&:group_id).uniq
    user_ids.uniq!
    users = User.where(id: user_ids)
    user_recs = {}
    users.each{|u| user_recs[u.id] = {email: u.email, first_name: u.first_name, last_name: u.last_name}}
    file.write( {"Users" => user_recs}.to_yaml )

  end

  def import

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
