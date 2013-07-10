class AdminMailer < ActionMailer::Base

  self.default :from => "CivicEvolution <support@civicevolution.org>",
               :reply_to => "support@civicevolution.org"

  def follow_us(email)
    @email = email
    mail(:to => "Info at CivicEvolution <info@civicevolution.org>",
         :subject => 'Follow request')
  end

end
