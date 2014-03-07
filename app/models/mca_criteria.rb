class McaCriteria < ActiveRecord::Base
  attr_accessible :multi_criteria_analysis_id, :category, :title, :text, :order_id, :range, :weight

  belongs_to :mca, class_name: "MultiCriteriaAnalysis", foreign_key: 'multi_criteria_analysis_id', primary_key: 'id'
  has_many :ratings, class_name: "McaRating", dependent: :destroy

  before_create :set_defaults

  def set_defaults
    self.text ||= self.title
    self.category = ''
    self.range ||= "1..5"
    self.weight ||= 1
    self.order_id ||= self.mca.criteria.maximum(:order_id) + 1 || 1
  end
  
  def update(key, value)
    Rails.logger.debug "McaCriteria.update"
    self.update_attribute(key,value)
    json = self.attributes
    json[:key] = key
    json
  end

end
