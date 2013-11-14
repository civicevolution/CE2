class McaOption < ActiveRecord::Base
  attr_accessible :multi_criteria_analysis_id, :title, :text, :order_id

  belongs_to :multi_criteria_analysis
  has_many :evaluations, class_name: 'McaOptionEvaluation'


end
