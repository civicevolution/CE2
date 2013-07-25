class ChangeSendEmailAtToDailyInNotificationRequests < ActiveRecord::Migration
  def up
    remove_column :notification_requests, :send_email_at
    add_column :notification_requests, :send_daily, :boolean
  end
  def down
    remove_column :notification_requests, :send_daily
    add_column :notification_requests, :send_email_at, :datetime
  end
end


