class AddPropertiesToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :privacy, :hstore
    add_column :conversations, :published, :boolean, default: false
    add_column :conversations, :ends_at, :datetime
    add_column :conversations, :list, :boolean
  end
end
