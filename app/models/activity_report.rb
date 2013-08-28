class ActivityReport < ActiveRecord::Base
  attr_accessible :action, :user_id, :conversation_code, :ip_address, :details

  after_create :send_email_to_admin

  def send_email_to_admin
    # don't send email more than once in 10 minutes
    last_sent = ActivityReport.maximum(:notification_sent_at)
    if Time.now > last_sent + 10.minutes
      AdminMailer.delay.activity_report(self)
      self.update_column(:notification_sent_at, Time.now)
    end
  end

end
