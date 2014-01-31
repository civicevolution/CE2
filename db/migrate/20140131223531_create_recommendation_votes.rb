class CreateRecommendationVotes < ActiveRecord::Migration
  def change
    create_table :recommendation_votes do |t|
      t.integer :group_id
      t.integer :voter_id
      t.integer :conversation_id
      t.integer :recommendation

      t.timestamps
    end
  end
end
