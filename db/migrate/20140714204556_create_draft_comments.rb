class CreateDraftComments < ActiveRecord::Migration
  def change
    create_table :draft_comments do |t|
      t.string :code
      t.json :data
      t.integer :user_id

      t.timestamps
    end
    add_index :draft_comments, :code, unique: true
  end
end