class Autosave < ActiveRecord::Base

  attr_accessible :user_id, :code, :data

  before_create :autosave_code_is_unique, unless: Proc.new { |a| a.code || a.user_id }

  def self.save(current_user_id, autosave_code, data)
    Rails.logger.debug "Autosave.save to user_id: #{current_user_id} or code: #{autosave_code}"

    if current_user_id
      if autosave_code
        code_action = :clear
        Autosave.find_by(code: autosave_code).destroy
      end
      autosave = Autosave.where(user_id: current_user_id).first_or_create
    elsif autosave_code
      autosave = Autosave.where(code: autosave_code).first_or_create
    else
      autosave = Autosave.create
      autosave_code = autosave.code
      code_action = :store
    end

    autosave.update_column(:data, data.to_json)

    ['ok', code_action, autosave_code]
  end

  def self.load(current_user_id, autosave_code)
    Rails.logger.debug "Autosave.load for user_id: #{current_user_id} or code: #{autosave_code}"
    # for now, user_id takes precedence over the code

    if current_user_id
      autosave_by_user_id = Autosave.find_by(user_id: current_user_id)
    end

    if autosave_code
      autosave_by_code = Autosave.find_by(code: autosave_code)
    end

    if autosave_by_user_id
      data = autosave_by_user_id.data
      if autosave_code
        code_action = :clear
        autosave_by_code.destroy
      end
    elsif autosave_by_code
      data = autosave_by_code.data
    else
      data = {}
    end

    [data, code_action, autosave_code]
  end


  def self.clear(current_user_id, autosave_code)
    Rails.logger.debug "Autosave.clear for user_id: #{current_user_id} or code: #{autosave_code}"
    # for now, user_id takes precedence over the code

    if current_user_id
      autosave_by_user_id = Autosave.find_by(user_id: current_user_id).destroy
    end

    if autosave_code
      autosave_by_code = Autosave.find_by(code: autosave_code).destroy
    end
  end


  def autosave_code_is_unique
    self.code = Autosave.create_random_autosave_code
    while( Autosave.exists?(code: self.code) ) do
      self.code = Autosave.create_random_autosave_code
    end
  end

  def self.create_random_autosave_code
    # I want each invite to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...20).map{ o[rand(o.length)] }.join
  end


end
