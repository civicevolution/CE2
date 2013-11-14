# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mca_rating do
    mca_option_evaluation_id 1
    mca_criteria_id 1
    rating 1
  end
end
