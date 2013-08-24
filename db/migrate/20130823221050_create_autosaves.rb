class CreateAutosaves < ActiveRecord::Migration
  def change
    create_table :autosaves do |t|
      t.integer :user_id
      t.string :code
      t.json :data

      t.timestamps
    end
    add_index :autosaves, :user_id, unique: true
    add_index :autosaves, :code, unique: true
  end
end
