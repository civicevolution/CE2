require 'spec_helper'

describe Initiative do
  subject('initiative'){ FactoryGirl.build(:initiative) }

  it {should validate_presence_of (:title) }
  it {should validate_presence_of (:description) }

  it "expect title to be demo initiative" do
    expect(initiative.title).to eq( 'demo initiative')
  end

  it "expect description to be demo initiative" do
    expect(initiative.description).to eq( 'description of demo initiative')
  end

  it { should have_many(:issues)}

end
