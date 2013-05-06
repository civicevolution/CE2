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

  it "expect title to be My issue title: punctuated" do
    expect(issue.title).to eq( 'My issue title: punctuated')
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

  it "expect to_param to return the munged title as my-issue-title-punctuated" do
    expect(issue.to_param).to eq('my-issue-title-punctuated')
  end


  it "expect munged_title to get calculated and saved as my-issue-title-punctuated" do
    issue.save
    expect(issue.munged_title).to eq('my-issue-title-punctuated')
  end


end
