class Agenda < ActiveRecord::Base
  attr_accessible :title, :description, :code, :access_code, :template_name, :list, :status
  has_many :agenda_roles
  has_many :agenda_activities

  validate :code_is_unique, on: :create

  def code_is_unique
    self.code = Agenda.create_random_code
    while( Agenda.where(code: self.code).exists? ) do
      self.code = Agenda.create_random_code
    end
  end

  def self.create_random_code
    # I want each conversation to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...10).map{ o[rand(o.length)] }.join
  end

  def get_user_for_accept_role(current_user, data)
    #Rails.logger.debug "Agenda.sign_in my_id: #{self.id}"

    case data[:role]
      when "coordinator"
        data[:identifier] = 1
        email = "agenda-#{self.id}-coordinator-#{data[:identifier]}@civicevolution.org"
      when "themer"
        email = "agenda-#{self.id}-themer-#{data[:identifier]}@civicevolution.org"
      when "group"
        email = "agenda-#{self.id}-group-#{data[:identifier]}@civicevolution.org"
      when "reporter"
        data[:identifier] = 1
        email = "agenda-#{self.id}-reporter-#{data[:identifier]}@civicevolution.org"
    end

    rec = self.agenda_roles.find_by( name: data[:role], identifier: data[:identifier])
    if rec.nil?
      raise "CivicEvolution::AgendaAcceptNoRole No role for name:#{data[:role]}, identifier: #{data[:identifier]}"
    elsif !rec.access_code.nil? && rec.access_code != data[:access_code]
      raise "CivicEvolution::AgendaAcceptBadAccessCode Wrong access_code #{data[:access_code]} for name: #{data[:role]}, identifier: #{data[:identifier]}"
    end

    user = User.find_by(email: email)
    if user.nil?
      raise "CivicEvolution::AgendaAcceptNoUser No user for email: #{email}, name:#{data[:role]}, identifier: #{data[:identifier]}"
    end
    # return the user to controller to sign in
    user
  end

  def release_role(current_user)
    #Rails.logger.debug "Agenda.sign_out my_id: #{self.id}"

  end


end
