class DraftComment < ActiveRecord::Base

  attr_accessible :data, :user_id

  belongs_to :user

  before_create :set_unique_code

  def set_unique_code
    self.code = DraftComment.create_random_autosave_code
    while( DraftComment.exists?(code: self.code) ) do
      self.code = DraftComment.create_random_autosave_code
    end
  end

  def self.create_random_autosave_code
    # I want each invite to have a unique code for identification
    o =  [('a'..'z'),(0..9)].map{|i| i.to_a}.flatten
    (0...20).map{ o[rand(o.length)] }.join
  end

end
