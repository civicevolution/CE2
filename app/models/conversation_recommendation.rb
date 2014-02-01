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
    conversation = Conversation.includes(:title_comment).find_by(code: params["conversation_code"])

    recommendation_options = [
      {recommendation: 1, text: 'Big decrease'},
      {recommendation: 2, text: 'Little decrease'},
      {recommendation: 3, text: 'Stay the same'},
      {recommendation: 4, text: 'Little increase'},
      {recommendation: 5, text: 'Big increase'}
    ]

    recommendation_votes = {}
    total_votes = 0
    max_votes = 0
    RecommendationVote.select('recommendation, count(*)').where(conversation_id: conversation.id).group(:recommendation).each do |rv|
      recommendation_votes[rv.recommendation] = rv.count
      total_votes += rv.count
      max_votes = rv.count unless max_votes > rv.count
    end
    max_votes = max_votes.to_f
    total_votes = total_votes.to_f

    recommendation_options.each do |ro|
      votes = recommendation_votes[ro[:recommendation]] || 0
      ro[:votes] = votes
      ro[:percentage] = total_votes > 0 ? (votes/total_votes*100).round : 0
      ro[:graph_percentage] = max_votes > 0 ? (votes/max_votes*100).round : 0
    end

    {title: conversation.title, recommendation_options: recommendation_options}
  end

end