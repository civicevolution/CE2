class McaOption < ActiveRecord::Base
  include ActiveModel::Dirty
  #define_attribute_methods :data

  attr_accessible :multi_criteria_analysis_id, :title, :text, :order_id, :category

  belongs_to :mca, class_name: "MultiCriteriaAnalysis", foreign_key: 'multi_criteria_analysis_id', primary_key: 'id'
  belongs_to :multi_criteria_analysis, class_name: "MultiCriteriaAnalysis", foreign_key: 'multi_criteria_analysis_id', primary_key: 'id'
  has_many :evaluations, class_name: 'McaOptionEvaluation', dependent: :destroy

  before_create :set_defaults

  def set_defaults
    self.text ||= self.title
    if self.order_id.nil?
      max_id = self.mca.options.maximum(:order_id) || 0
      self.order_id = max_id + 1
    end
  end

  def add_evaluation(params)
    evaluation = nil
    if params[:user_id]
      params[:user_id].each do |user_id|
        puts user_id
        evaluation = McaOptionEvaluation.where(user_id: user_id, mca_option_id: self.id).first_or_create do |evaluation|
          evaluation.category = params[:category]
        end
        evaluation.update_attribute(:status, params[:status])
      end
    else
      # add a plenary evaluation
    end
    evaluation
  end

  def update(key, value)
    Rails.logger.debug "McaOption.update"
    self.update_attribute(key,value)
    json = self.attributes
    json[:key] = key
    json
  end

  def process_update_option(current_user, type, data)
    case type
      when "service_level_recommendation"
        data.values[0]['group'] = "#{current_user.last_name}"
        self.update_option( data )
      when "service_suggestion"
        data.values[0]['group'] = "#{current_user.last_name}"
        self.update_option( data )
      when "service_recommendation"
        data.values[0]['group'] = "#{current_user.last_name}"
        self.update_option( data )
      when "delete_suggestion", "delete_recommendation", "delete_budget_direction"
        data.values[0]['group'] = "#{current_user.last_name}"
        self.update_option( data )
      else
        raise "CivicEvolution::UpdateOption type not recognized for type: #{type}"

    end

  end


  def update_option(option_data)
    updates = []
    data = nil
    option_data.each_pair do |key, value|
      if self.attributes.has_key? key.to_s
        self.update_attribute(key, value)
        updates.push({key: key, value: value})
      else
        data ||= self.data.try{|data| data.symbolize_keys} || { id_seq: 1 }
        if key.match(':')
          (mode,key) = key.split(':',2)
        else
          mode = nil
        end

        if value.nil?
          data_will_change!
          data.delete(key.to_sym)
        elsif mode == "push"
          data_will_change!
          if value[:_id]
            mode = "replace"
            value.delete('group') # replace shouldn't update the group
            data[key.to_sym].each do |el|
              if el['_id'] == value[:_id]
                el.replace(el.merge(value))
              end
            end
          else
            value[:_id] = "#{ data[:id_seq]+=1}"
            data[key.to_sym] = [] if data[key.to_sym].nil?
            data[key.to_sym].push(value)
          end
        elsif mode == 'delete'
          #Rails.logger.debug "delete this key: #{key} with id "
          child = data[key.to_sym].detect{|s| s['_id'] == value['id'] }
          data[key.to_sym].delete(child) unless child.nil?
        else
          data_will_change!
          data[key.to_sym] = value
        end
        key = "#{mode}:#{key}" unless mode.nil?
        updates.push({key: key, value: value})
      end
    end
    if data
      self.update_attribute(:data, data)
    end
    updates
  end

end
