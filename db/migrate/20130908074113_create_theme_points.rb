class CreateThemePoints < ActiveRecord::Migration
  def change
    create_table :theme_points do |t|
      t.integer :group_id
      t.integer :theme_id
      t.integer :points

      t.timestamps
    end
  end
end
