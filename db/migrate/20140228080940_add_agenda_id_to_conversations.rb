class AddAgendaIdToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :agenda_id, :integer
  end
end
