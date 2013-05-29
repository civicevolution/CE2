class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.integer :user_id
      t.has_attached_file :photo

      t.timestamps
    end
  end
end
