class CreateAgendaComponents < ActiveRecord::Migration
  def change
    create_table :agenda_components do |t|
      t.integer :agenda_id
      t.string :code
      t.string :descriptive_name
      t.string :type
      t.json :input
      t.json :output
      t.string :status
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
