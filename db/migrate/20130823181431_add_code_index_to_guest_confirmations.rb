class AddCodeIndexToGuestConfirmations < ActiveRecord::Migration
  def change
    add_index :guest_confirmations, :code, unique: true
  end
end
