class FollowCe < ActiveRecord::Base
  attr_accessible :email

  after_create :send_email_to_admin

  def send_email_to_admin
    AdminMailer.delay.follow_us(self.email)
  end

end
