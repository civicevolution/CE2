class AddStartsAtToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :starts_at, :datetime
  end
end
