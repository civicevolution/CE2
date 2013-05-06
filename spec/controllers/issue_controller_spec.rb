require 'spec_helper'

describe IssuesController do
  subject('issue'){ FactoryGirl.create(:issue) }

  #describe "GET 'show'" do
  #  it "should be successful" do
  #    pp issue.inspect
  #    get "issues/#{issue.id}"
  #    response.should be_success
  #  end
  #end

  it "routes to #show" do
    { get: "/issues/1"}.should route_to(
        controller: 'issues',
        action: 'show',
        issue_id: '1'
    )
  end


  it "get issue/munged-title routes to issue#show" do
  { :get => "/issues/demo-title" }.
  should route_to(
    controller: "issues",
    action: 'show',
    munged_title: "demo-title"
  )
  end

  xit "get to unknown issue should raise ActiveRecord::RecordNotFound" do
    #expect { get: "/issues/100" }.to raise_error(ActiveRecord::RecordNotFound)
  end


  #it "should return 404 for deleted articles" do
  #  @article = Factory :article, :status => "deleted"
  #  expect { get edit_article_path(:id => @article.id) }.to raise_error(ActiveRecord::RecordNotFound)
  #end

  # http://stackoverflow.com/questions/2385799/how-to-redirect-to-a-404-in-rails
  #describe "user view" do
  #  before do
  #    get :show, :id => 'nonsense'
  #  end
  #
  #  it { should_not assign_to :user }
  #
  #  it { should respond_with :not_found }
  #  it { should respond_with_content_type :html }
  #
  #  it { should_not render_template :show }
  #  it { should_not render_with_layout }
  #
  #  it { should_not set_the_flash }
  #end

end
