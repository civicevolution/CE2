# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :allocation_item do
    theme_id 1
    order_id 1
    letter "MyString"
  end
end
