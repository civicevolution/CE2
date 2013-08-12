require 'spec_helper'

describe Api::V1::ConversationsController, :type => :api do

  before (:each) do
    @conversation = FactoryGirl.create(:conversation)
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "test something" do

    it "returns http success" do
      get 'index', format: :json
      response.should be_success
    end

    it "returns http success" do
      get 'show', id: @conversation.code, format: :json
      response.should be_success
    end

    it "should be publicly accessible by default" do
      get 'show', id: @conversation.code, format: :json
      response.should be_success
    end

    it "should be fully private if summary and comments are false" do
      @conversation = FactoryGirl.create(:conversation, privacy: {summary: "false", comment: "false"})
      pp @conversation.inspect
      get 'show', id: @conversation.code, format: :json
      response.should be_success
    end

  end

  describe "GET 'index'" do
    xit "returns http success" do
      get 'index', format: :json
      response.should be_success
    end
  end


  #before do
  #  @user = create_user!
  #  @user.update_attribute(:admin, true)
  #  @user.permissions.create!(:action => "view",
  #                            :thing => project)
  #end

  #let(:token) { @user.authentication_token }
  #
  #context "index" do
  #  before do
  #    5.times do
  #      Factory(:ticket, :project => project, :user => @user)
  #    end
  #  end
  #
  #  let(:url) { "/api/v2/projects/#{project.id}/tickets" }
  #
  #  it "XML" do
  #    get "#{url}.xml", :token => token
  #    last_response.body.should eql(project.tickets.to_xml)
  #  end
  #
  #  it "JSON" do
  #    get "#{url}.json", :token => token
  #    last_response.body.should eql(project.tickets.to_json)
  #  end
  #end

  #context "pagination" do
  #  before do
  #    100.times do
  #      Factory(:ticket, :project => project, :user => @user)
  #    end
  #  end
  #
  #  it "gets the first page" do
  #    get "/api/v2/projects/#{project.id}/tickets.json",
  #        :token => token,
  #        :page => 1
  #
  #    last_response.body.should eql(project.tickets.page(1).per(50).to_json)
  #  end
  #
  #  it "gets the second page" do
  #    get "/api/v2/projects/#{project.id}/tickets.json?page=2",
  #        :token => token,
  #        :page => 2
  #
  #    last_response.body.should eql(project.tickets.page(2).per(50).to_json)
  #  end
  #end

end