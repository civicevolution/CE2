class McaOption < ActiveRecord::Base
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


end
