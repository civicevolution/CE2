class Comment < ActiveRecord::Base
  attr_accessible :liked, :name, :text
  
  #validates :password, :length => { :in => 6..20
  
  validate :my_test
  
  def my_test
    #errors.add(:text, "My text error message")
    #errors.add(:name, "My name error message")
    #errors.add(:text, "must be at least #{range[1]} characters") unless length >= range[1].to_i
    #errors.add(:text, "must be no longer than #{range[2]} characters") unless length <= range[2].to_i
    #false
  end
  
end
