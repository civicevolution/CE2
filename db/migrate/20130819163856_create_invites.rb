class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.integer :sender_user_id
      t.string :first_name
      t.string :last_name
      t.string :email
      t.text :text
      t.string :code
      t.integer :conversation_id
      t.hstore :options

      t.timestamps
    end
    add_index :invites, :code, unique: true
  end
end
