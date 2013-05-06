require 'spec_helper'

describe Issue do
  subject('issue'){ FactoryGirl.build(:issue) }

  it {should validate_presence_of (:initiative_id) }
  it {should validate_presence_of (:user_id) }
  it {should validate_presence_of (:title) }
  it {should validate_presence_of (:description) }
  it {should validate_presence_of (:version) }
  it {should validate_presence_of (:status) }
  it {should validate_presence_of (:purpose) }

  it "expect initiative_id to be 1" do
    expect(issue.initiative_id).to eq( 1 )
  end

  it "expect user_id to be 1" do
    expect(issue.user_id).to eq( 1 )
  end

  it "expect title to be issue title" do
    expect(issue.title).to eq( 'issue title')
  end

  it "expect description to be issue description" do
    expect(issue.description).to eq( 'issue description')
  end

  it "expect version to be 1" do
    expect(issue.version).to eq( 1 )
  end

  it "expect status to be open" do
    expect(issue.status).to eq( 'open')
  end

  it "expect purpose to be issue purpose" do
    expect(issue.purpose).to eq( 'issue purpose')
  end

  it { should belong_to (:user)}
  it { should belong_to (:initiative)}
  it { should have_many (:questions)}

end
