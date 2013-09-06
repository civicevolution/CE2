class CreateCommentThreads < ActiveRecord::Migration
  def change
    create_table :comment_threads do |t|
      t.integer :child_id, null: false
      t.integer :parent_id, null: false
      t.integer :order_id, null: false

      t.timestamps
    end
  end
end
