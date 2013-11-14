# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mca_option_evaluation do
    user_id 1
    mca_option_id 1
    order_id 1
    type ""
    status "MyString"
    notes "MyText"
  end
end
