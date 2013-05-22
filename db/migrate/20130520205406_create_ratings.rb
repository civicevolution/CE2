class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :ratable_id, null: false
      t.string  :ratable_type, null: false
      t.integer :version, null: false
      t.integer :user_id, null: false
      t.integer :rating, null: false
    end
  end
end
