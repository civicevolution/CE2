require 'development_mail_interceptor'
require 'unsubscribe_mail_interceptor'

# prevent DEV email from being sent to actual user email addresses
ActionMailer::Base.register_interceptor(UnsubscribeMailInterceptor)
ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) unless Rails.env.production?