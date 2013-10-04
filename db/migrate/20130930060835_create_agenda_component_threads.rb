class CreateAgendaComponentThreads < ActiveRecord::Migration
  def change
    create_table :agenda_component_threads do |t|
      t.integer :agenda_id
      t.integer :child_id
      t.integer :parent_id
      t.integer :order_id

      t.timestamps
    end
  end
end
