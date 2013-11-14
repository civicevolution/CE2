# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mca_criterium, :class => 'McaCriteria' do
    multi_criteria_analysis_id 1
    type ""
    title "MyString"
    text "MyText"
    order_id 1
    range "MyString"
    weight 1.5
  end
end
