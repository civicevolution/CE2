class McaOption < ActiveRecord::Base
  attr_accessible :multi_criteria_analysis_id, :title, :text, :order_id

  belongs_to :multi_criteria_analysis
  has_many :evaluations, class_name: 'McaOptionEvaluation'

  def add_evaluation(params)
    if params[:user_id]
      params[:user_id].each do |user_id|
        puts user_id
        evaluation = McaOptionEvaluation.where(user_id: user_id, mca_option_id: self.id).first_or_create do |evaluation|
          evaluation.category = params[:category]
        end
        evaluation.update_attribute(:status, params[:status])
      end
    else
      # add a planery evaluation
    end
  end


end
