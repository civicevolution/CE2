class CreateActivityReports < ActiveRecord::Migration
  def change
    create_table :activity_reports do |t|
      t.string :action
      t.integer :user_id
      t.string :conversation_code
      t.inet :ip_address
      t.hstore :details
      t.datetime :notification_sent_at

      t.timestamps
    end
  end
end
