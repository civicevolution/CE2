class McaRating < ActiveRecord::Base
  attr_accessible :mca_option_evaluation_id, :mca_criteria_id, :rating

  belongs_to :mca_option_evaluation
  belongs_to :mca_criteria

  after_save :send_to_firebase


  def send_to_firebase
    mca_id = self.mca_option_evaluation.mca_option.multi_criteria_analysis_id
    data = {
      mca_option_evaluation_id: self.mca_option_evaluation_id,
      mca_criteria_id: self.mca_criteria_id,
      rating: self.rating,
      updated_at: self.updated_at
    }
    Firebase.base_uri = "https://civicevolution.firebaseio.com/mca/#{mca_id}/updates/"
    Firebase.push '', { class: self.class.to_s, action: "update", data: data, updated_at: Time.now.getutc, source: "RoR-Firebase" }
  end
  handle_asynchronously :send_to_firebase

end
