class CreateMentions < ActiveRecord::Migration
  def change
    create_table :mentions do |t|
      t.integer :comment_id
      t.integer :version
      t.integer :user_id
      t.integer :mentioned_user_id

      t.timestamps
    end
  end
end
