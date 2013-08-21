class UnsubscribeMailInterceptor
  def self.delivering_email(message)
    recipient = message.to[0].downcase
    if Unsubscribe.where(email: recipient).exists?
      # cancel this email
      message.perform_deliveries = false
      #Rails.logger.debug "Interceptor prevented sending mail #{message.inspect}!"
      MAIL_SUMMARY_LOGGER.warn "BLOCKED To: #{recipient}, Subject: #{message.subject}"
    else

      token = LogEmail.create( email: recipient, subject: message.subject ).token
      href = "#{UNSUBSCRIBE_HOST}/unsubscribe/#{token}"

      message.body.parts.each do |body_part|
        body_part.header.fields.each do |field|
          if field.value == "text/html"
            body_part.body.raw_source.safe_concat( %Q|<p class="unsubscribe">Click here to <a href="#{href}">unsubscribe</a></p>| )
            break
          elsif field.value == "text/plain"
            body_part.body.raw_source.safe_concat( %Q|\n\nClick here to unsubscribe: #{href}| )
            break
          end
        end
      end

    end
  end
end
