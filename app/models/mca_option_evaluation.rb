class McaOptionEvaluation < ActiveRecord::Base
  attr_accessible :user_id, :mca_option_id, :order_id, :category, :status, :notes

  belongs_to :mca_option
  belongs_to :user
  has_many :ratings, class_name: McaRating

  before_validation :set_order_id, unless: Proc.new{|moe| moe.order_id}

  def set_order_id
    # find the evals this user has
    mca_options = McaOption.find(mca_option_id).multi_criteria_analysis.options
    self.order_id = (McaOptionEvaluation.where(user_id: user_id, mca_option_id: mca_options.map(&:id)).maximum(:order_id) || 0) + 1
  end

end
