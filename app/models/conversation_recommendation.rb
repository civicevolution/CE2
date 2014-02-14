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
      votes[ vote.recommendation ] = vote.num_of_votes
    end

    # :votes, :conversations_list, :agenda_code, :title
    {
        title: conversation.title,
        agenda_code: agenda_details["code"],
        code: conversation.code,
        vote_options: conversation.details.try{|details| details['vote_options']}||[],
        privacy: conversation.privacy,
        #final_themes: final_themes,
        role: Ability.abilities(params["current_user"], 'Conversation', conversation.id),
        current_timestamp: Time.new.to_i,
        votes: votes
    }
  end

  def self.data_recommendation_results(params)
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])

    option_votes = {}
    total_votes = 0
    max_votes = 0
    RecommendationVote.select('recommendation, sum(num_of_votes)').where(conversation_id: conversation.id).group(:recommendation).each do |rv|
      option_votes[rv.recommendation] = rv.sum
      total_votes += rv.sum
      max_votes = rv.sum unless max_votes > rv.sum
    end
    max_votes = max_votes.to_f
    total_votes = total_votes.to_f

    vote_options = conversation.details.try{|details| details['vote_options']}||[]

    vote_options.each do |vo|
      votes = option_votes[vo['key'].to_i] || 0
      vo[:votes] = votes
      vo[:percentage] = total_votes > 0 ? (votes/total_votes*100).round : 0
      vo[:graph_percentage] = max_votes > 0 ? (votes/max_votes*100).round : 0
    end

    table_votes = {}
    RecommendationVote.where(conversation_id: conversation.id).each do |vote|
      table_votes["g#{vote.group_id}-r#{vote.recommendation}"] = vote.num_of_votes
    end

    {title: conversation.title, vote_options: vote_options, table_votes: table_votes}
  end

end