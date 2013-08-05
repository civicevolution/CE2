class CreateBookmarks < ActiveRecord::Migration
  def change
    create_table :bookmarks do |t|
      t.integer :user_id
      t.integer :target_id
      t.string :target_type
      t.integer :version

      t.timestamps
    end
    add_index :bookmarks, :user_id
  end
end
