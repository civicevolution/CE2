class Contact < ActiveRecord::Base

  attr_accessible :user_id, :first_name, :last_name, :email, :text, :reference_type, :reference_id, :action

  after_create :send_email_to_admin

  def send_email_to_admin
    AdminMailer.delay.contact_us_notification(self)
  end
end
