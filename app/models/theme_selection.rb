class ThemeSelection < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :final_themes, :votes, :allocated_points, :participant_worksheet_data, :conversations_list, :agenda_code

  def data(params, current_user)
    # Let serializer do the serialization
    #final_theme_ids << conversation.final_themes.map(&:id)
    #conversation.final_themes = conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id)

    self.agenda_code = self.code
    conversations = Conversation.includes(:title_comment).where(id: self.input[ "conversations_list_ids" ])
    self.conversations_list = []
    final_theme_ids = []
    self.input[ "conversations_list_ids" ].each do |id|
      conversation = conversations.detect{|c| c.id == id}
      conversation_data = { code: conversation.code, title: conversation.title}

      final_themes = []
      ltr = 'A'
      conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id).each do |theme|
        final_themes.push({
          id: theme.id,
          letter: ltr,
          text: theme.text.gsub(/\[quote.*\/quote\]/m,'')
        })
        ltr = ltr.succ
        final_theme_ids << theme.id
      end

      conversation_data[:final_themes] = final_themes
      self.conversations_list.push( conversation_data )
    end

    all_votes = ThemeVote.where(group_id: current_user.last_name.to_i, theme_id: final_theme_ids.flatten )
    self.votes = {}
    all_votes.each do |vote|
      self.votes[ vote.voter_id ] = [] unless self.votes[ vote.voter_id ]
      self.votes[ vote.voter_id ].push( {theme_id: vote.theme_id} )
    end

    self
  end

  def self.data_themes_select_page_data(params)
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
    current_user = params["current_user"]
    coord_user_id = params["coordinator_user_id"].to_i
    agenda_details = params["agenda_details"]

    final_themes = []
    final_theme_ids = []
    ltr = 'A'
    conversation.theme_comments.where(user_id: coord_user_id ).order(:order_id).each do |theme|
      final_themes.push({
                          id: theme.id,
                          letter: ltr,
                          text: theme.text.gsub(/\[quote.*\/quote\]/m,'')
                        })
      ltr = ltr.succ
      final_theme_ids << theme.id
    end
    all_votes = ThemeVote.where(group_id: current_user.last_name.to_i, theme_id: final_theme_ids.flatten )
    votes = {}
    all_votes.each do |vote|
      votes[ vote.voter_id ] = [] unless votes[ vote.voter_id ]
      votes[ vote.voter_id ].push( {theme_id: vote.theme_id} )
    end
    # :votes, :conversations_list, :agenda_code, :title
    {
        title: conversation.title,
        agenda_code: agenda_details["code"],
        code: conversation.code,
        privacy: conversation.privacy,
        final_themes: final_themes,
        role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
        current_timestamp: Time.new.to_i,
        votes: votes
    }
  end

  def self.data_themes_select_results(params)
    conversation_code = params["conversation_code"]
    coordinator_user_id = params["coordinator_user_id"].to_i


    if conversation_code.match(/-/)
      agenda_code, data_set_code = conversation_code.match(/^(\w+)-(.*)$/).captures
      agenda = Agenda.find_by(code: agenda_code)
      data_set_details = agenda.details["data_sets"][data_set_code]
      title = data_set_details["data_set_title"]
      agenda_details = agenda.details
      link_details = {}

      # check if there are any parameters that need to be evaluated for their interpolated variables
      data_set_details["parameters"].each_pair do |key,value|
        Rails.logger.debug "value for eval: #{value}"
        data_set_details["parameters"][key] = eval( '"' + value + '"') if value.class.to_s == 'String' && value.match(/#/)
      end
      coord_user_id = data_set_details["parameters"]["coordinator_user_id"].to_i
      conversation_ids = data_set_details["parameters"]["conversation_ids"].scan(/\d+/).map(&:to_i)
      top_themes_count = data_set_details["parameters"]["top_themes_count"]

      themes = ThemeAllocation.collect_top_themes_from_conversations(coord_user_id, conversation_ids, top_themes_count)
      themes = ThemeComment.where(id: themes.map{|t| t[:theme_id]})

    else
      conversation = Conversation.find_by(code: conversation_code)
      themes = ThemeComment.where(conversation_id: conversation.id, user_id: coordinator_user_id)
      title = conversation.title
    end

    allocated_themes = ThemeVote.themes_votes(themes)
    {title: title, allocated_themes: allocated_themes}
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
    #conversation = Conversation.includes(:title_comment).find_by(id: self.input[ "conversation_id" ])
    conversations = Conversation.includes(:title_comment).where(id: self.input[ "conversations_list_ids" ])
    conversation = conversations[0]

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
    self.conversation = Conversation.includes(:title_comment).find_by(code: params[:conv_code])

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

  def report_data(conversation_code)

    self.votes = ThemeVote.theme_votes(conversation_code, self.input[ "coordinator_user_id" ])

    #self.results()
    #
    #ltr = 'A'
    #theme_comments = []
    #self.theme_comments.each do |theme|
    #  theme_comments.push( {id: id, letter: ltr, text: theme.text}
    #  )
    #  ltr = ltr.succ
    #end
    #theme_comments
  end

  def participant_worksheet(params, current_user)
    conversations = Conversation.includes(:title_comment).where(id: self.input[ "conversations_list_ids" ])
    self.conversations_list = []
    final_theme_ids = []
    self.input[ "conversations_list_ids" ].each do |id|
      conversation = conversations.detect{|c| c.id == id}
      conversation_data = { code: conversation.code, title: conversation.title}

      final_themes = []
      ltr = 'A'
      conversation.theme_comments.where(user_id: self.input[ "coordinator_user_id" ]).order(:order_id).each do |theme|
        final_themes.push({
                              id: theme.id,
                              letter: ltr,
                              text: theme.text.gsub(/\[quote.*\/quote\]/m,'')
                          })
        ltr = ltr.succ
        final_theme_ids << theme.id
      end
      conversation_data[:final_themes] = final_themes
      self.conversations_list.push( conversation_data )
    end
    self
  end


  private
  def assign_defaults
    self.menu_roles = ['group', 'participant_report']
  end

end