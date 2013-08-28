class AdminMailer < ActionMailer::Base

  self.default :from => "CivicEvolution <support@civicevolution.org>",
               :reply_to => "support@civicevolution.org"

  def host
    if Rails.env.development?
      "http://app.civicevolution.dev:8001"
    else
      "http://app.civicevolution.org"
    end
  end


  def follow_us(email)
    @email = email
    mail(:to => "Info at CivicEvolution <info@civicevolution.org>",
         :subject => 'Follow request')
  end

  def contact_us_notification(contact)
    @contact = contact
    @sender = User.find_by(id: contact.user_id)
    @reference = if @contact.reference_type == 'Conversation'
                   Conversation.find_by(code: @contact.reference_id)
                 else
                   {type: @contact.reference_type, id: @contact.reference_id}
                 end
    @host=host

    mail(:to => "Contact Us at CivicEvolution <admin@civicevolution.org>",
         :subject => 'Contact Us message')

  end

end
