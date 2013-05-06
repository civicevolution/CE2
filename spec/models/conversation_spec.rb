require 'spec_helper'

describe Conversation do
  subject('conversation'){ FactoryGirl.build(:conversation) }

  it {should validate_presence_of (:question_id) }
  it {should validate_presence_of (:status) }

  it "expect question_id to be 1" do
    expect(conversation.question_id).to eq( 1 )
  end

  it "expect status to be open" do
    expect(conversation.status).to eq( 'open')
  end

  it { should belong_to (:question)}
  it { should have_many(:conversation_comments)}
  it { should have_many(:summary_comments)}

end
