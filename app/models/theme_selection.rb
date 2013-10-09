class ThemeSelection < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :final_themes, :votes, :allocated_points, :participant_worksheet_data

  def data(params, current_user)
    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    self.final_themes = self.conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)

    all_votes = ThemeVote.where(group_id: current_user.last_name.to_i, theme_id: self.final_themes.map(&:id) )
    self.votes = {}
    all_votes.each do |vote|
      self.votes[ vote.voter_id ] = [] unless self.votes[ vote.voter_id ]
      self.votes[ vote.voter_id ].push( {theme_id: vote.theme_id} )
    end

    self.final_themes.each do |theme|
      theme.text = theme.text.gsub(/\[quote.*\/quote\]/,'')
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
    conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    details[:links] =  [ {
        title: conversation.title,
        munged_title: conversation.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50],
        conversation_code: conversation.code,
        href: "/#/cmp/#{self.code}/select/#{conversation.munged_title}"
      }
    ]
    details
  end

  def results(params, current_user)
    self.conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])

    self.votes = ThemeVote.theme_votes(self.conversation.code, self.input[ "coordinator_user_id" ])

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
    worksheet_data = []
    Conversation.includes(:title_comment).where(id: self.input[ "worksheet_conversation_ids" ]).order(:starts_at).each do |conversation|
      themes = []
      conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id).each do |theme|
        themes.push( { text: theme.text.gsub(/\[quote.*\/quote\]/,'') })
      end
      worksheet_data.push( {title: conversation.title, essential_themes: themes })
    end
    worksheet_data
  end


  private
  def assign_defaults
    self.menu_roles = ['group', 'participant_report']
  end

end