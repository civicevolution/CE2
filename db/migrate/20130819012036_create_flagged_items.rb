class CreateFlaggedItems < ActiveRecord::Migration
  def change
    create_table :flagged_items do |t|
      t.integer :user_id
      t.integer :conversation_id
      t.integer :target_id
      t.string :target_type
      t.string :category
      t.text :statement
      t.integer :version

      t.timestamps
    end
    add_index :flagged_items, [:target_id, :target_type]
  end
end
