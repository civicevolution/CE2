class DropTableAllocationItems < ActiveRecord::Migration
  def change
    drop_table :allocation_items
  end
end
