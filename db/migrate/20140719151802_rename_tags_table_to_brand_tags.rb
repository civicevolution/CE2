class RenameTagsTableToBrandTags < ActiveRecord::Migration
  def change
    rename_table :tags, :brand_tags
  end
end
