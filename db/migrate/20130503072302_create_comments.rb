class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :type, null: false
      t.belongs_to :user, null: false
      t.belongs_to :conversation, null: false
      t.text :text, null: false
      t.integer :version, default: 1
      t.string :status, default: 'new'
      t.integer :order_id
      t.string :purpose
      t.string :references

      t.timestamps
    end

    add_index :comments, :conversation_id
    add_index :comments, :user_id
  end
end