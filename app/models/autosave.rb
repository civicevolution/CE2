class Autosave < ActiveRecord::Base

  attr_accessible :user_id, :code, :data, :belongs_to_user_id

  before_create :autosave_code_is_unique, unless: Proc.new { |a| a.code || a.user_id }

  def self.save(current_user_id, autosave_code, data)
    Rails.logger.debug "Autosave.save to user_id: #{current_user_id} or code: #{autosave_code}"

    if current_user_id
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

    if autosave_by_user_id && autosave_by_code
      # return the most recent one and store the older one by the same autosave_code
      if autosave_by_user_id.updated_at > autosave_by_code.updated_at
        autosave_by_user_id.update_attributes( code: nil)
        autosave_by_code.update_attributes( user_id: nil, belongs_to_user_id: current_user_id)
        data = autosave_by_user_id.data
      else
        autosave_by_user_id.update_attributes( user_id: nil) # clear user_id so I can set it on other record
        autosave_by_code.update_attributes( user_id: current_user_id, code: nil)
        autosave_by_user_id.update_attributes( code: autosave_code, belongs_to_user_id: current_user_id)
        data = autosave_by_code.data
      end
    elsif autosave_by_user_id
      data = autosave_by_user_id.data
    elsif autosave_by_code
      data = autosave_by_code.data
    else
      data = {}
    end

    data
  end


  def self.clear(current_user_id, autosave_code)
    Rails.logger.debug "Autosave.clear for user_id: #{current_user_id} or code: #{autosave_code}"
    # for now, user_id takes precedence over the code

    if current_user_id
      autosave_by_user_id = Autosave.find_by(user_id: current_user_id)
      if autosave_by_user_id
        autosave_by_user_id.destroy
        # is there another autosave record with the same code
        older_autosave = Autosave.find_by(belongs_to_user_id: autosave_by_user_id.user_id)
      end
      if older_autosave
        older_autosave.update_attributes( user_id: current_user_id, code: nil)
      end
      return older_autosave
    elsif autosave_code
      Autosave.find_by(code: autosave_code).destroy
      return nil
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
