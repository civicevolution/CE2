class RecommendationVote < ActiveRecord::Base
  attr_accessible :conversation_id, :group_id, :recommendation, :num_of_votes
end
