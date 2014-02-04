class CreateTestTable < ActiveRecord::Migration
  def change
    create_table :test_tables do |t|
      t.integer :id_957
    end
  end
end
