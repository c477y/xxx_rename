# frozen_string_literal: true

RSpec.shared_examples "a scene mapper" do
  let(:call) { described_class.new(config) }

  it "should return expected response" do
    resp = call.search(filename)
    expect(resp).to eq_scene_data(scene_data)
  end
end

RSpec.shared_examples "a nil scene mapper" do
  let(:call) { described_class.new(config) }

  it "should raise a NoMatchError" do
    expect { call.search(filename) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
  end
end

RSpec.shared_examples "a successful actor matcher" do
  let(:call) { described_class.new(config).actor_details(actor) }

  let(:expected_response) do
    {
      "name" => expected_name,
      "gender" => expected_gender
    }
  end

  it "should return expected response" do
    expect(call).to eq(expected_response)
  end
end

RSpec.shared_examples "a nil actor matcher" do
  let(:call) { described_class.new(config).actor_details("abcxyz") }
  let(:expected_response) { nil }

  it "should return expected response" do
    expect(call).to eq(expected_response)
  end
end
