class CreateNotificationRequests < ActiveRecord::Migration
  def change
    create_table :notification_requests do |t|
      t.integer :conversation_id, null: false
      t.integer :user_id, null: false
      t.boolean :immediate_me
      t.boolean :immediate_all
      t.datetime :send_at

      t.timestamps
    end

    add_index :notification_requests, [:conversation_id, :user_id]

  end
end
