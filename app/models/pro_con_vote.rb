class ProConVote < ActiveRecord::Base
  attr_accessible :comment_id, :pro_votes, :con_votes
end
