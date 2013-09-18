class CreateAllocationThemes < ActiveRecord::Migration
  def change
    create_table :allocation_themes do |t|
      t.string :code
      t.integer :theme_ids, array: true

      t.timestamps
    end
  end
end
