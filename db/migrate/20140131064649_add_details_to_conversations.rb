class AddDetailsToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :details, :json
  end
end
