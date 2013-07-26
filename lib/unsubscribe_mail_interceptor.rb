class UnsubscribeMailInterceptor
  def self.delivering_email(message)
    recipient = message.to[0]
    if Unsubscribe.where(email: recipient.downcase).exists?
      # cancel this email
      message.perform_deliveries = false
      #Rails.logger.debug "Interceptor prevented sending mail #{message.inspect}!"
      MAIL_SUMMARY_LOGGER.warn "BLOCKED To: #{recipient}, Subject: #{message.subject}"
    else
      MAIL_SUMMARY_LOGGER.info "To: <#{recipient}>, Subject: #{message.subject}"
    end
  end
end
