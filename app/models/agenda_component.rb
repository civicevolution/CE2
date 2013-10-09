class AgendaComponent < ActiveRecord::Base

  attr_accessible :agenda_id, :code, :descriptive_name, :type, :input, :output, :status, :starts_at, :ends_at, :menu_roles

  belongs_to :agenda

  has_many :parent_targets, class_name: 'AgendaComponentThread', foreign_key: :child_id

  has_many :child_targets, -> { order 'order_id ASC' }, class_name: 'AgendaComponentThread', foreign_key: :parent_id

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

  def data
    raise "CivicEvolution::AgendaComponentDataNotDefined No data for #{self.class.to_s}"
  end

  def menu_details(role,email)
    raise "CivicEvolution::AgendaComponentMenuDetailsNotDefined No menu_details for #{self.class.to_s}"
  end

  def results
    raise "CivicEvolution::AgendaComponentResultsNotDefined No results for #{self.class.to_s}"
  end

end
