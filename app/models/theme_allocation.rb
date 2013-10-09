class ThemeAllocation < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :final_themes, :votes, :allocated_points

  def data(params, current_user)
    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    self.final_themes = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)

    all_votes = ThemePoint.where(group_id: current_user.last_name.to_i, theme_id: self.final_themes.map(&:id) )
    self.votes = {}
    all_votes.each do |vote|
      self.votes[ vote.voter_id ] = [] unless self.votes[ vote.voter_id ]
      self.votes[ vote.voter_id ].push( {theme_id: vote.theme_id, points: vote.points} )
    end

    self.final_themes.each do |theme|
      theme.text = theme.text.gsub(/\[quote.*\/quote\]/,'')
    end

    self
  end

  def menu_details(role)
    details = {
        type: self.class.to_s,
        descriptive_name: self.descriptive_name,
        code: self.code,
        starts_at: self.starts_at,
        ends_at: self.ends_at,
        menu_template: 'theme-allocation'
    }
    conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    details[:links] =  []
    details[:links].push(
        {
            title: conversation.title,
            href: "/#/cmp/#{self.code}/allocate/#{conversation.munged_title}"
        }
    ) if role == 'group'
    details[:links].push(
        {
            title: conversation.title,
            href: "/#/cmp/#{self.code}/allocate-worksheet/#{conversation.munged_title}"
        }
    ) if role == 'reporter'
    details[:links].push(
        {
            title: conversation.title,
            href: "/#/cmp/#{self.code}/allocate-results/#{conversation.munged_title}"
        }
    ) if ['coordinator', 'reporter'].include?(role)
    details
  end

  def results(params, current_user)

    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    self.final_themes = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)

    theme_ids = self.final_themes.map(&:id)
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
      theme = self.final_themes.detect{|t| t.id == id}
      points = theme_points[id] || 0
      allocated_points.push( {id: id, letter: ltr, text: theme.text.gsub(/\[quote.*\/quote\]/,''),
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


  private
  def assign_defaults
    self.menu_roles = ['group', 'participant_report', 'coordinator', 'reporter']
  end

end