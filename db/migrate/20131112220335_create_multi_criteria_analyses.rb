class CreateMultiCriteriaAnalyses < ActiveRecord::Migration
  def change
    create_table :multi_criteria_analyses do |t|
      t.integer :agenda_id
      t.string :title
      t.string :description

      t.timestamps
    end
  end
end
