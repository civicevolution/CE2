class AddCodeToThemePoints < ActiveRecord::Migration
  def change
    add_column :theme_points, :code, :string
  end
end
