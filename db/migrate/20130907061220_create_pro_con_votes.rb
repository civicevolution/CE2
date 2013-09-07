class CreateProConVotes < ActiveRecord::Migration
  def change
    create_table :pro_con_votes do |t|
      t.integer :comment_id
      t.integer :pro_votes
      t.integer :con_votes

      t.timestamps
    end
  end
end
