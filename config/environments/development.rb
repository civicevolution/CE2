Ce2::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # ActionMailer Config
  config.action_mailer.default_url_options = { :host => 'localhost' }
  
  # change to true to allow email to be sent during development
  config.action_mailer.perform_deliveries = true
  # Disable delivery errors, bad email addresses will NOT be ignored
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"

  #config.action_mailer.logger = ActiveSupport::BufferedLogger.new( "#{Rails.root}/log/mail.sent.log" )
  
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :enable_starttls_auto => true,
    :address => "smtp.sendgrid.net",
    :domain => 'civicevolution.org',
    :port => 587,
    :user_name => "civicevolution2SFO", 
    :password	=> "gayjorge2011CANYON",
    :authentication => :plain, 
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  RES_BASE='civic_dev'
end
