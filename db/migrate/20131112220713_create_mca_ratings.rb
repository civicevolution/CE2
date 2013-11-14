class CreateMcaRatings < ActiveRecord::Migration
  def change
    create_table :mca_ratings do |t|
      t.integer :mca_option_evaluation_id
      t.integer :mca_criteria_id
      t.integer :rating

      t.timestamps
    end
  end
end
