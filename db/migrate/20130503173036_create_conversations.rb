class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.integer :question_id, null: false
      t.string :status, null: false, default: 'open'

      t.timestamps
    end
  end
end
