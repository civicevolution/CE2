class CreateUnsubscribes < ActiveRecord::Migration
  def change
    create_table :unsubscribes do |t|
      t.string :email

      t.timestamps
    end
  end
end
