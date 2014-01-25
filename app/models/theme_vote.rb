class ThemeVote < ActiveRecord::Base

  attr_accessible :group_id,  :voter_id, :theme_id, :code

  def self.themes_votes(themes)
    votes = ThemeVote.where(theme_id: themes.map(&:id)).count(:group => "theme_id")

    results = []
    total_votes = 0.to_f
    max_votes = 0
    themes.each do |theme|
      num_votes = votes[theme.id] || 0
      total_votes += num_votes
      max_votes = num_votes unless max_votes > num_votes
      result = { theme_id: theme.id, text: theme.text, votes: num_votes }
      results.push result
    end
    max_votes = max_votes.to_f

    results.each do |result|
      #if result[:votes].nil? || result[:votes] = 0
      #  result[:percent] = 0
      #else
      result[:percentage] = total_votes > 0 ? (result[:votes]/total_votes*100).round : 0
      result[:graph_percentage] = max_votes > 0 ? (result[:votes]/max_votes*100).round : 0
      #end
    end
    results = results.sort{|b,a| a[:votes] <=> b[:votes]}
    #results[0][:highlight] = true
    #results[1][:highlight] = true
    results
  end


  def self.theme_votes(conversation_code, user_id)
    conversation = Conversation.find_by(code: conversation_code)
    themes = ThemeComment.where(conversation_id: conversation.id, user_id: user_id, published: true)
    votes = ThemeVote.where(theme_id: themes.map(&:id)).count(:group => "theme_id")

    results = []
    total_votes = 0.to_f
    max_votes = 0
    themes.each do |theme|
      num_votes = votes[theme.id] || 0
      total_votes += num_votes
      max_votes = num_votes unless max_votes > num_votes
      result = { theme_id: theme.id, text: theme.text, votes: num_votes, published: theme.published }
      results.push result
    end
    max_votes = max_votes.to_f

    results.each do |result|
      #if result[:votes].nil? || result[:votes] = 0
      #  result[:percent] = 0
      #else
        result[:percentage] = total_votes > 0 ? (result[:votes]/total_votes*100).round : 0
        result[:graph_percentage] = max_votes > 0 ? (result[:votes]/max_votes*100).round : 0
      #end
    end
    results = results.sort{|b,a| a[:votes] <=> b[:votes]}
    #results[0][:highlight] = true
    #results[1][:highlight] = true
    results
  end

end
