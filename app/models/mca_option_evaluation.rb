class McaOptionEvaluation < ActiveRecord::Base
  attr_accessible :user_id, :mca_option_id, :order_id, :category, :status, :notes

  belongs_to :mca_option
  has_many :ratings, class_name: McaRating

end
