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
        allocation_themes.push( {id: theme[:theme_id], text: theme[:text].gsub(/\[quote.*\/quote\]/m,'')} )
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
    theme_ids.each do |id|
      theme = allocation_themes.detect{|t| t[:id] == id}
      points = theme_points[id] || 0
      allocated_points.push( {id: id, letter: ltr, text: theme[:text],
                              points: points,
                              percentage: total_points > 0 ? (points/total_points*100).round : 0,
                              graph_percentage: max_points > 0 ? (points/max_points*100).round : 0
                             }
      )
      ltr = ltr.succ
    end

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
    self.final_themes = allocation_themes
    self
  end

  private
  def assign_defaults
    self.menu_roles = ['group', 'participant_report', 'coordinator', 'reporter']
  end

end