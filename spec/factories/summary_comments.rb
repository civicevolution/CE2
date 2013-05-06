# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :summary_comment do
    type "SummaryComment"
    user_id 1
    conversation_id 1
    text "Summary comment text"
    version 1
    status "new"
    order_id 1
    purpose "purpose"
    references "references"
  end
end

