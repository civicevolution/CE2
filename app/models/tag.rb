class Tag < ActiveRecord::Base

  attr_accessible :text

  validates_presence_of :text
  validate :at_least_three_chars
  validates :text, length: { maximum: 250 }

  def at_least_three_chars
    if text.gsub(/\s/,'').length < 2
      errors[:text] << "Tag must have at least 2 characters"
      return false
    end
  end

end

