class AddDataToMultiCriteriaAnalyses < ActiveRecord::Migration
  def change
    add_column :multi_criteria_analyses, :data, :json
  end
end
