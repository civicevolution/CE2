# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conversation do
    code "123abc456"
    user_id 1
    starts_at Time.now
    ends_at Time.now + 14.days
    privacy public: "true"
    list true
    published true
    status "new"
    daily_report_hour 7
    last_report_sent_at Time.now
  end
end

