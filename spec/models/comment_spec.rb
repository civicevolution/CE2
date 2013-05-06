require 'spec_helper'

describe Comment do
  subject("comment") { FactoryGirl.build(:comment) }

  it "should be valid when new" do
    expect(comment).to be_valid
  end

  it {should validate_presence_of (:user_id) }
  it {should validate_presence_of (:conversation_id) }
  it {should validate_presence_of (:text) }
  it {should validate_presence_of (:status) }
  it {should validate_presence_of (:order_id) }
  it {should validate_presence_of (:type) }
  it {should validate_presence_of (:version) }

  it "expect comment.user_id to be 1" do
    expect(comment.user_id).to eq(1)
  end

  it "expect comment.conversation_id to be 1" do
    expect(comment.conversation_id).to eq(1)
  end

  it { should belong_to (:user)}
  it { should belong_to (:conversation)}


end

