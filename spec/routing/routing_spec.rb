require 'spec_helper'

describe "routing to issues" do
  subject('issue'){ FactoryGirl.create(:issue) }

  xit "get issue/NUMBER routes to issue#show" do
    { :get => "/issues/1" }.
    should route_to(
      controller: "issues",
      action: 'show',
      issue_id: "1"
    )
  end

  xit "get issue/munged-title routes to issue#show" do
    { :get => "/issues/demo-title" }.
      should route_to(
        controller: "issues",
        action: 'show',
        munged_title: "demo-title"
    )
  end

end