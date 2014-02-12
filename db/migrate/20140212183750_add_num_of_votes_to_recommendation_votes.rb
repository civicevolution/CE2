class AddNumOfVotesToRecommendationVotes < ActiveRecord::Migration
  def change
    add_column :recommendation_votes, :num_of_votes, :integer, default: 0
  end
end
