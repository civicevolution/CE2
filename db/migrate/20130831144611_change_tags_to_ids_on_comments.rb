class ChangeTagsToIdsOnComments < ActiveRecord::Migration
  def change
    remove_column :comments, :tags, :string, array: true
    add_column :comments, :reference_ids, :integer, array: true
  end
end
