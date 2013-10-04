# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :agenda_component_thread do
    child_id 1
    parent_id 1
    order_id 1
  end
end
