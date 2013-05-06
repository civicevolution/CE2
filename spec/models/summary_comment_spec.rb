require 'spec_helper'

describe SummaryComment do
  let(:comment){ FactoryGirl.build(:summary_comment) }

  it {should validate_presence_of (:type) }

  it "expect comment.type to be SummaryComment" do
    expect(comment.type).to eq( 'SummaryComment')
  end

end
