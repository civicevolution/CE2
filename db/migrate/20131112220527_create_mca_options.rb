class CreateMcaOptions < ActiveRecord::Migration
  def change
    create_table :mca_options do |t|
      t.integer :multi_criteria_analysis_id
      t.string :title
      t.text :text
      t.integer :order_id

      t.timestamps
    end
  end
end
