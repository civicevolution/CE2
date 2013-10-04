class AddVoterIdToThemePoints < ActiveRecord::Migration
  def change
    add_column :theme_points, :voter_id, :integer
  end
end
