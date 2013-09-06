class RemoveReferencesIdsFromComments < ActiveRecord::Migration
  def change
    remove_column :comments, :reference_ids, :integer, array: true
  end
end
