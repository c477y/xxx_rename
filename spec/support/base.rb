# frozen_string_literal: true

RSpec.shared_examples "a successful actor matcher" do
  let(:expected_response) do
    {
      "name" => expected_name,
      "gender" => expected_gender
    }
  end

  it "should return expected response" do
    expect(@result).to eq(expected_response)
  end
end

RSpec.shared_examples "a nil actor matcher" do
  let(:expected_response) { nil }

  it "should return expected response" do
    expect(@result).to eq(expected_response)
  end
end
