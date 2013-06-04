require 'spec_helper'

describe ConversationComment do
  let(:comment){ FactoryGirl.build(:conversation_comment) }

  it {should validate_presence_of (:type) }

  it "expect comment.type to be ConversationComment" do
    expect(comment.type).to eq( 'ConversationComment')
  end

  it "should increment the order_id for the conversation_comment in the conversation" do
    com1 = FactoryGirl.create(:conversation_comment, conversation_id: 100, order_id: 100 )
    #pp com1.inspect
    #pp com1.author.inspect
    com2 = FactoryGirl.create(:conversation_comment, conversation_id: 100, order_id: nil )
    #pp com2.inspect
    #pp com2.author.inspect
    expect(com2.order_id).to eq(101)
  end

end
