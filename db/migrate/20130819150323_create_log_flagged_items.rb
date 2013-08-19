class CreateLogFlaggedItems < ActiveRecord::Migration
  def change
    create_table :log_flagged_items do |t|
      t.integer :user_id
      t.integer :conversation_id
      t.integer :target_id
      t.string :target_type
      t.string :category
      t.text :statement
      t.integer :version

      t.datetime :posted_at
      t.hstore   :review_details

      t.timestamps
    end
    add_index :log_flagged_items, [:target_id, :target_type]
  end
end
