class AddDetailsToMcaOptions < ActiveRecord::Migration
  def change
    add_column :mca_options, :details, :hstore
  end
end
