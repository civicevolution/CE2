class ChangeSendAtToSendEmailAtInNotificationRequests < ActiveRecord::Migration
  def change
    rename_column :notification_requests, :send_at, :send_email_at
  end
end
