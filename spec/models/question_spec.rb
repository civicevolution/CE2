require 'spec_helper'

describe Question do
  subject('question'){ FactoryGirl.build(:question) }

  it {should validate_presence_of (:issue_id) }
  it {should validate_presence_of (:user_id) }
  it {should validate_presence_of (:text) }
  it {should validate_presence_of (:version) }
  it {should validate_presence_of (:status) }
  it {should validate_presence_of (:purpose) }

  it "expect issue_id to be 1" do
    expect(question.issue_id).to eq( 1 )
  end

  it "expect user_id to be 1" do
    expect(question.user_id).to eq( 1 )
  end

  it "expect text to be question text" do
    expect(question.text).to eq( 'question text')
  end

  it "expect version to be 1" do
    expect(question.version).to eq( 1 )
  end

  it "expect status to be open" do
    expect(question.status).to eq( 'open')
  end

  it "expect purpose to be question purpose" do
    expect(question.purpose).to eq( 'question purpose')
  end

  it { should belong_to (:user)}
  it { should belong_to (:issue)}
  it { should have_many (:conversations)}

end
