class LogGuestConfirmation < ActiveRecord::Base

  def self.log guest_confirmation, user, details = nil
    log = LogGuestConfirmation.new
    log.user_id = user.id
    log.conversation_id = guest_confirmation.conversation_id
    log.posted_at = guest_confirmation.created_at
    log.details = details
    log.save
  end

end
