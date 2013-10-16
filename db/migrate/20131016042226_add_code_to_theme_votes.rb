class AddCodeToThemeVotes < ActiveRecord::Migration
  def change
    add_column :theme_votes, :code, :string
  end
end
