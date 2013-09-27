class CreateAgendaRoles < ActiveRecord::Migration
  def change
    create_table :agenda_roles do |t|
      t.integer :agenda_id
      t.string :name
      t.integer :identifier
      t.string :access_code

      t.timestamps
    end
  end
end
