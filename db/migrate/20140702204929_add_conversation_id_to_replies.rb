class AddConversationIdToReplies < ActiveRecord::Migration
  def change
    add_column :replies, :conversation_id, :integer
  end
end
