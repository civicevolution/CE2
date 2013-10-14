class AddConversationIdsToAgendas < ActiveRecord::Migration
  def change
    add_column :agendas, :conversation_ids, :integer, array: true
  end
end
