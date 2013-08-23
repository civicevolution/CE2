class CreateGuestConfirmations < ActiveRecord::Migration
  def change
    create_table :guest_confirmations do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :code
      t.integer :conversation_id

      t.timestamps
    end
  end
end
