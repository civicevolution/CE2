class ThemeVote < ActiveRecord::Base

  attr_accessible :group_id,  :voter_id, :theme_id

  def self.theme_votes(conversation_code)
    conversation = Conversation.find_by(code: conversation_code)
    votes = ThemeVote.count(:group => "theme_id")
    #total_votes = 0.to_f
    #votes.each_value{|v| total_votes += v }
    themes = ThemeComment.where(conversation_id: conversation.id)
    results = []
    total_votes = 0.to_f
    themes.each do |theme|
      num_votes = votes[theme.id] || 0
      total_votes += num_votes
      result = { theme_id: theme.id, text: theme.text, votes: num_votes }
      results.push result
    end
    results.each do |result|
      #if result[:votes].nil? || result[:votes] = 0
      #  result[:percent] = 0
      #else
        result[:percent] = (result[:votes]/total_votes*100).round
      #end
    end
    results.sort{|b,a| a[:votes] <=> b[:votes]}
    results[0][:highlight] = true
    results[1][:highlight] = true
    results
  end

end
