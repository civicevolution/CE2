class CreateFollowCes < ActiveRecord::Migration
  def change
    create_table :follow_ces do |t|
      t.string :email

      t.timestamps
    end
  end
end
