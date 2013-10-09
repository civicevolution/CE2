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

  def get_user_for_accept_role( data)
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

  def agenda_data(current_user)
    # get the role for this user
    if current_user.nil?
      menu_data = []
    else
      role = current_user.email.match(/agenda-\d+-(\w+)-\d/).try{ |matches| matches[1] } || ''
      role_relevant_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, role).order(:starts_at)
      menu_data = role_relevant_components.map{|c| c.menu_details(role, current_user.email)}.compact
    end

    details = {
        title: self.title,
        munged_title: self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50],
        description: self.description,
        code: self.code,
        template_name: template_name,
        menu_data: menu_data
    }
  end

  def role_menu_data(current_user)
    # get the role for this user
    role = current_user.email.match(/agenda-\d+-(\w+)-\d/)[1]
    role_relevant_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, role).order(:ends_at)
    menu_data = role_relevant_components.map{|c| c.menu_details(role, current_user.email)}.compact
  end

  def munged_title
    self.title.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]
  end

  def participant_report
    participant_report_components = AgendaComponent.where("agenda_id = ? AND (?) = ANY (menu_roles)",self.id, 'participant_report').order(:starts_at)
    participant_report_components.map(&:participant_report_details)
  end

end
