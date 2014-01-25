class CreateMcaCriteria < ActiveRecord::Migration
  def change
    create_table :mca_criteria do |t|
      t.integer :multi_criteria_analysis_id
      t.string :category
      t.string :title
      t.text :text
      t.integer :order_id
      t.string :range
      t.float :weight

      t.timestamps
    end
  end
end
