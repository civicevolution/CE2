require 'spec_helper'

describe Api::V1::UsersController, :type => :api do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "GET 'user'" do

    it "should be successful" do
      get :user, :format => :json
      response.should be_success
    end

  end

end
