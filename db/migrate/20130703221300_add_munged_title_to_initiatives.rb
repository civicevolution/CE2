class AddMungedTitleToInitiatives < ActiveRecord::Migration
  def change
    add_column :initiatives, :munged_title, :string
  end
end
