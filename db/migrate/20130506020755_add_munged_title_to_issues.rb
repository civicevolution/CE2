class AddMungedTitleToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :munged_title, :string
  end
end
