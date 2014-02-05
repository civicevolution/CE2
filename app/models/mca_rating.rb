class McaRating < ActiveRecord::Base
  attr_accessible :mca_option_evaluation_id, :mca_criteria_id, :rating

  attr_accessor :post_process_disabled

  belongs_to :mca_option_evaluation
  belongs_to :mca_criteria

  after_save :realtime_notification, unless: :post_process_disabled


  def realtime_notification
    mca_id = self.mca_option_evaluation.mca_option.multi_criteria_analysis_id
    data = {
      mca_option_evaluation_id: self.mca_option_evaluation_id,
      mca_criteria_id: self.mca_criteria_id,
      rating: self.rating,
      updated_at: self.updated_at
    }
    message = { class: self.class.to_s, action: "update", data: data, updated_at: Time.now.getutc, source: "RoR-RT-Notification" }
    channel = "/mca/#{mca_id}/rating"
    Modules::FayeRedis::publish(message,channel)
  end
  handle_asynchronously :realtime_notification

end
