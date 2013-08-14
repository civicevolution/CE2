class CreateGuestPosts < ActiveRecord::Migration
  def change
    create_table :guest_posts do |t|
      t.string :post_type
      t.integer :user_id
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :conversation_id
      t.text :text
      t.string :purpose
      t.integer :reply_to_id
      t.integer :reply_to_version
      t.boolean :request_to_join

      t.timestamps
    end
  end
end
