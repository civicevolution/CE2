class CreateLogReviewedComments < ActiveRecord::Migration
  def change
    create_table :log_reviewed_comments do |t|
      t.integer :comment_id
      t.string :type
      t.integer :user_id
      t.integer :conversation_id
      t.text :text
      t.integer :version
      t.string :status
      t.integer :order_id
      t.string :purpose
      t.integer :references
      t.integer :published
      t.datetime :posted_at
      t.hstore :review_details

      t.timestamps
    end
  end
end
