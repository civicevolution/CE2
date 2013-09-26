class CreateParkedComments < ActiveRecord::Migration
  def change
    create_table :parked_comments do |t|
      t.integer :conversation_id
      t.integer :user_id
      t.integer :parked_ids, array: true

      t.timestamps
    end
  end
end
