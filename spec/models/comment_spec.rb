require 'spec_helper'

describe Comment do
  subject("comment") { FactoryGirl.build(:comment) }

  it "should be valid when new" do
    expect(comment).to be_valid
  end

  it "should not increment version if text doesn't change" do
    subject.save
    version_number = subject.version
    id = subject.id
    new_comment = Comment.find(id)
    new_comment.save
    expect(new_comment.version).to eq(version_number)
  end

  it "should increment version if text changes" do
    subject.save
    version_number = subject.version
    id = subject.id
    pp subject.inspect
    new_comment = Comment.find(id)
    new_comment.text = '01234567890123456789-v2'
    pp new_comment.inspect
    expect { new_comment.save }.to change { new_comment.version }.to(version_number+1)
  end


  it {should validate_presence_of (:user_id) }
  it {should validate_presence_of (:conversation_id) }

  it { should ensure_length_of(:text).is_at_least(20).with_message(/at least 20 characters/) }

  it {should validate_presence_of (:status) }
  it {should validate_presence_of (:order_id) }
  it {should validate_presence_of (:type) }
  it {should validate_presence_of (:version) }

  it "expect comment.conversation_id to be 1" do
    expect(comment.conversation_id).to eq(1)
  end

  it { should belong_to (:author)}
  it { should belong_to (:conversation)}

  it "should increment the comment version each time the record is updated" do
    com1 = FactoryGirl.create(:conversation_comment, conversation_id: 100, version: 10 )
    #pp com1.inspect
    com1.save
    #pp com1.inspect
    expect(com1.version).to eq(11)
  end

end

