class CreateUiLabels < ActiveRecord::Migration
  def change
    create_table :ui_labels do |t|
      t.string :tag
      t.string :language
      t.string :text

      t.timestamps
    end
  end
end
