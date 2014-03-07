class AddCategoryToMcaOptions < ActiveRecord::Migration
  def change
    add_column :mca_options, :category, :string
  end
end
