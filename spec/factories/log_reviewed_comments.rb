# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :log_reviewed_comment do
    comment_id 1
    type ""
    user_id 1
    conversation_id 1
    text "MyText"
    version 1
    status "MyString"
    order_id 1
    purpose "MyString"
    references 1
    published 1
    posted_at "2013-08-16 12:21:58"
    review_details ""
  end
end
