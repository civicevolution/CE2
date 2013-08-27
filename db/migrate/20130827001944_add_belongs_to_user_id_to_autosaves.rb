class AddBelongsToUserIdToAutosaves < ActiveRecord::Migration
  def change
    add_column :autosaves, :belongs_to_user_id, :integer
  end
end
