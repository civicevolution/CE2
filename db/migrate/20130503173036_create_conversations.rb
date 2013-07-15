class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.string :code, null: false
      t.integer :user_id, null: false
      t.string :status, null: false, default: 'open'

      t.timestamps
    end

    add_index :conversations, :code,  :unique => true

  end
end
