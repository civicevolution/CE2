class DropTableAllocationThemes < ActiveRecord::Migration
  def change
    drop_table :allocation_themes
  end
end
