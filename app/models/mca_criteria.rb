class McaCriteria < ActiveRecord::Base
  attr_accessible :multi_criteria_analysis_id, :category, :title, :text, :order_id, :range, :weight

  belongs_to :multi_criteria_analysis
  has_many :ratings, class_name: "McaRating"

end
