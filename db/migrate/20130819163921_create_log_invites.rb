class CreateLogInvites < ActiveRecord::Migration
  def change
    create_table :log_invites do |t|
      t.integer :sender_user_id
      t.string :first_name
      t.string :last_name
      t.string :email
      t.text :text
      t.string :code
      t.integer :conversation_id
      t.hstore :options

      t.hstore :details
      t.integer :user_id
      t.datetime :invited_at

      t.timestamps
    end
  end
end
