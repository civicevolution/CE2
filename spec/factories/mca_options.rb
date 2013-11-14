# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mca_option do
    multi_criteria_analysis_id 1
    title "MyString"
    text "MyText"
    order_id 1
  end
end
