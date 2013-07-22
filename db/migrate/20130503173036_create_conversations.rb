class CreateConversations < ActiveRecord::Migration
  def change
    execute "create extension hstore"
    create_table :conversations do |t|
      t.string :code, null: false
      t.integer :user_id, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.hstore :privacy
      t.boolean :list,  default: false
      t.boolean :published,  default: false
      t.string :status, null: false, default: 'new'

      t.timestamps
    end

    add_index :conversations, :code,  :unique => true

  end
end
