class DropConversationIdsFromAgenda < ActiveRecord::Migration
  def up
    remove_column :agendas, :conversation_ids
  end

  def down
    add_column :agendas, :conversation_ids, :integer, array: true
  end
end
