class AddCodeAndUserIdToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :code, :string, :unique => true
    add_column :conversations, :user_id, :integer

    add_index :conversations, :code
  end
end
