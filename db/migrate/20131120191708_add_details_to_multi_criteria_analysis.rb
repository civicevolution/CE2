class AddDetailsToMultiCriteriaAnalysis < ActiveRecord::Migration
  def change
    add_column :multi_criteria_analyses, :details, :hstore
  end
end
