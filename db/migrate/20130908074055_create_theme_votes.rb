class CreateThemeVotes < ActiveRecord::Migration
  def change
    create_table :theme_votes do |t|
      t.integer :group_id
      t.integer :voter_id
      t.integer :theme_id

      t.timestamps
    end
  end
end
