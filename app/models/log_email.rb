class LogEmail < ActiveRecord::Base

  attr_accessible :email, :subject

  before_create :truncate_subject

  def truncate_subject
    self.subject = self.subject[0..254]
  end

  validate :email_token_is_unique, on: :create

  def email_token_is_unique
    self.token = LogEmail.create_random_token
    while( LogEmail.where(token: self.token).exists? ) do
      self.token = LogEmail.create_random_token
    end
  end

  def self.create_random_token
    # I want each conversation to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...20).map{ o[rand(o.length)] }.join
  end



end
