class CreateMcaOptionEvaluations < ActiveRecord::Migration
  def change
    create_table :mca_option_evaluations do |t|
      t.integer :user_id
      t.integer :mca_option_id
      t.integer :order_id
      t.string :category
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
