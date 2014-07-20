class Tag < ActiveRecord::Base

  attr_accessible :text

  validates_presence_of :text
  validate :at_least_three_chars
  validates :text, length: { maximum: 250 }

  def at_least_three_chars
    if text.gsub(/\s/,'').length < 3
      errors[:text] << "Tag must have at least 3 characters"
    end
  end

end

