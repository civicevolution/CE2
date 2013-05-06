require 'spec_helper'

describe ConversationComment do
  let(:comment){ FactoryGirl.build(:conversation_comment) }

  it {should validate_presence_of (:type) }

  it "expect comment.type to be ConversationComment" do
    expect(comment.type).to eq( 'ConversationComment')
  end


end
