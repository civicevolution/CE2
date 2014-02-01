class ConversationRecommendation < AgendaComponent
  after_initialize :assign_defaults, if: 'new_record?'

  attr_accessor :conversation, :final_themes, :votes, :allocated_points, :participant_worksheet_data, :conversations_list, :agenda_code

  def self.data_recommend_page_data(params)
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])
    current_user = params["current_user"]
    agenda_details = params["agenda_details"]

    all_votes = RecommendationVote.where(group_id: current_user.last_name.to_i, conversation_id: conversation.id )
    votes = {}
    all_votes.each do |vote|
      votes[ vote.voter_id ] = [] unless votes[ vote.voter_id ]
      votes[ vote.voter_id ].push( {recommendation: vote.recommendation} )
    end

    # :votes, :conversations_list, :agenda_code, :title
    {
        title: conversation.title,
        agenda_code: agenda_details["code"],
        code: conversation.code,
        privacy: conversation.privacy,
        #final_themes: final_themes,
        role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
        current_timestamp: Time.new.to_i,
        votes: votes
    }
  end

  def self.data_recommendation_results(params)
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

end