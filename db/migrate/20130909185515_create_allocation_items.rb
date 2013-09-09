class CreateAllocationItems < ActiveRecord::Migration
  def change
    create_table :allocation_items do |t|
      t.integer :theme_id
      t.integer :order_id
      t.string :letter
      t.text  :text

      t.timestamps
    end
  end
end
