class ThemeAllocation < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :final_themes, :votes, :allocated_points, :participant_worksheet_data, :allocation_themes

  def data(params, current_user)
    #self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    #self.final_themes = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)
    #self.final_themes.each do |theme|
    #  theme.text = theme.text.gsub(/\[quote.*\/quote\]/m,'')
    #end

    conversations = Conversation.where(id: self.input[ "conversations_list_ids" ]).order(:id)
    self.conversation = conversations[0]
    allocation_themes = []
    conversations.each do |conversation|
      themes = ThemeVote.theme_votes(conversation.code, self.input[ "coordinator_user_id" ])[0..2]
      themes.each do|theme|
        allocation_themes.push( {id: theme[:theme_id], text: theme[:text].gsub(/\[quote.*\/quote\]/m,'')} )
      end
    end
    self.allocation_themes = allocation_themes

    all_votes = ThemePoint.where(group_id: current_user.last_name.to_i, theme_id: self.allocation_themes.map{|at| at[:id]} )
    self.votes = {}
    all_votes.each do |vote|
      self.votes[ vote.voter_id ] = [] unless self.votes[ vote.voter_id ]
      self.votes[ vote.voter_id ].push( {theme_id: vote.theme_id, points: vote.points} )
    end

    self
  end

  def self.data_themes_allocate_page_data(params)
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
    current_user = params["current_user"]
    coord_user_id = params["coordinator_user_id"].to_i
    agenda_details = params["agenda_details"]

    allocation_themes = []
    allocation_theme_ids = []
    ltr = 'A'
    conversation.theme_comments.where(user_id: coord_user_id ).order(:order_id).each do |theme|
      allocation_themes.push({
                            id: theme.id,
                            letter: ltr,
                            text: theme.text.gsub(/\[quote.*\/quote\]/,'')
                        })
      ltr = ltr.succ
      allocation_theme_ids << theme.id
    end

    all_votes = ThemePoint.where(group_id: current_user.last_name.to_i, theme_id: allocation_theme_ids )
    votes = {}
    all_votes.each do |vote|
      votes[ vote.voter_id ] = [] unless votes[ vote.voter_id ]
      votes[ vote.voter_id ].push( {theme_id: vote.theme_id, points: vote.points} )
    end
    {
        title: conversation.title,
        agenda_code: agenda_details["code"],
        code: conversation.code,
        privacy: conversation.privacy,
        allocation_themes: allocation_themes,
        role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
        current_timestamp: Time.new.to_i,
        votes: votes
    }
  end

  def self.data_themes_allocation_results(params)
    conversation_code = params["conversation_code"]
    coordinator_user_id = params["coordinator_user_id"].to_i

    conversation = Conversation.find_by(code: conversation_code)
    themes = ThemeComment.where(conversation_id: conversation.id, user_id: coordinator_user_id)

    allocated_themes = ThemePoint.themes_points(themes)
    {title: conversation.title, allocated_themes: allocated_themes}
  end

  def menu_details(role,email)
    details = {
        type: self.class.to_s,
        descriptive_name: self.descriptive_name,
        code: self.code,
        starts_at: self.starts_at,
        ends_at: self.ends_at,
        menu_template: 'theme-allocation'
    }
    conversation = Conversation.includes(:title_comment).where(id: self.input[ "conversations_list_ids" ]).order(:id)[0]
    details[:links] =  []
    details[:links].push(
        {
            title: conversation.title,
            href: "/#/cmp/#{self.code}/allocate/#{conversation.munged_title}"
        }
    ) if role == 'group'
    details[:links].push(
        {
            title: "Display prioritisation results: #{conversation.title}",
            href: "/#/cmp/#{self.code}/allocate-worksheet/#{conversation.munged_title}"
        }
    ) if role == 'reporter'
    details[:links].push(
        {
            title: "Display prioritisation results: #{conversation.title}",
            href: "/#/cmp/#{self.code}/allocate-results/#{conversation.munged_title}"
        }
    ) if ['coordinator', 'reporter'].include?(role)
    details
  end

  def results(params, current_user)

    #self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    #
    #self.final_themes = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)
    #
    #theme_ids = self.final_themes.map(&:id)
    #theme_points = {}
    #total_points = 0.to_f
    #max_points = 0


    conversations = Conversation.where(id: self.input[ "conversations_list_ids" ]).order(:id)
    self.conversation = conversations[0]
    allocation_themes = []
    conversations.each do |conversation|
      themes = ThemeVote.theme_votes(conversation.code, self.input[ "coordinator_user_id" ])[0..2]
      themes.each do|theme|
        #allocation_themes.push( {id: theme[:theme_id], text: theme[:text].gsub(/\[quote.*\/quote\]/m,'') } )
        allocation_themes.push( {id: theme[:theme_id], text: theme[:text] } )
      end
    end

    theme_ids = allocation_themes.map{|at| at[:id] }
    theme_points = {}
    total_points = 0.to_f
    max_points = 0


    ThemePoint.select('theme_id, sum(points)').where(theme_id: theme_ids).group(:theme_id).each do |tp|
      theme_points[tp.theme_id] = tp.sum
      total_points += tp.sum
      max_points = tp.sum unless max_points > tp.sum
    end
    max_points = max_points.to_f

    ltr = 'A'
    allocated_points = []
    final_themes = []
    theme_ids.each do |id|
      theme = allocation_themes.detect{|t| t[:id] == id}
      points = theme_points[id] || 0
      allocated_points.push( {id: id, letter: ltr, text: theme[:text].gsub(/\[quote.*\/quote\]/m,''),
                              points: points,
                              percentage: total_points > 0 ? (points/total_points*100).round : 0,
                              graph_percentage: max_points > 0 ? (points/max_points*100).round : 0
                             })
      final_themes.push( {id: id, letter: ltr, text: theme[:text] })
      ltr = ltr.succ
    end

    self.final_themes = final_themes.sort{|a,b| a[:letter] <=> b[:letter]}
    self.allocated_points = allocated_points.sort{|b,a| a[:points] <=> b[:points]}

    self
  end

  def participant_report_details
    self.results(nil,nil)
    {
        klass: self.class.to_s,
        title: self.conversation.title,
        allocated_points: self.allocated_points
    }
  end

  def participant_worksheet(params, current_user)
    #worksheet_data = []
    #Conversation.includes(:title_comment).where(id: self.input[ "conversation_id" ]).order(:starts_at).each do |conversation|
    #  themes = []
    #  conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id).each do |theme|
    #    themes.push( { text: theme.text.gsub(/\[quote.*\/quote\]/m,'') })
    #  end
    #  worksheet_data.push( {title: conversation.title, essential_themes: themes })
    #end
    #worksheet_data

    conversations = Conversation.where(id: self.input[ "conversations_list_ids" ]).order(:id)
    allocation_themes = []
    conversations.each do |conversation|
      themes = ThemeVote.theme_votes(conversation.code, self.input[ "coordinator_user_id" ])[0..2]
      themes.each do|theme|
        allocation_themes.push( {theme_id: theme[:theme_id], text: theme[:text].gsub(/\[quote.*\/quote\]/m,'')} )
      end
    end
    allocation_themes
  end

  private
  def assign_defaults
    self.menu_roles = ['group', 'participant_report', 'coordinator', 'reporter']
  end

end