class CreateReportImages < ActiveRecord::Migration
  def change
    create_table :report_images do |t|
      t.integer :report_id
      t.has_attached_file :image

      t.timestamps
    end
  end
end
