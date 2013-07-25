class NotificationRequest < ActiveRecord::Base

  belongs_to :user
  belongs_to :conversation

  def update_request settings

    if settings[:immediate] == 'every'
      self.immediate_me = false
      self.immediate_all = true

    elsif settings[:immediate] == 'mine'
      self.immediate_me = true
      self.immediate_all = false

    else
      self.immediate_me = false
      self.immediate_all = false

    end

    self.immediate_me = settings[:immediate] == 'mine' ? true : false
    self.immediate_all = settings[:immediate] == 'every' ? true : false
    if settings[:daily]
      self.send_email_at = Time.now.change(:hour => 20)
    else
      self.send_email_at = nil
    end
    self.save

  end
end
