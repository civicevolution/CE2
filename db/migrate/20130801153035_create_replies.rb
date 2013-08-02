class CreateReplies < ActiveRecord::Migration
  def change
    create_table :replies do |t|
      t.integer :comment_id, null: false
      t.integer :reply_to_id, null: false

      t.timestamps
    end
  end
end
