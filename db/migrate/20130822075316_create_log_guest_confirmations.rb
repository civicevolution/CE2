class CreateLogGuestConfirmations < ActiveRecord::Migration
  def change
    create_table :log_guest_confirmations do |t|
      t.integer :user_id
      t.integer :conversation_id
      t.datetime :posted_at
      t.hstore :details

      t.timestamps
    end
  end
end
