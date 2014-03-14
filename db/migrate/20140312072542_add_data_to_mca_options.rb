class AddDataToMcaOptions < ActiveRecord::Migration
  def change
    add_column :mca_options, :data, :json
  end
end
