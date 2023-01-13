# frozen_string_literal: true

RSpec.shared_examples "a scene mapper" do
  let(:call) { described_class.new(config) }

  it "should return expected response" do
    resp = call.search(filename)
    scene_details = resp.to_h.except(:movie)
    scene_data_hash = scene_data.to_h.except(:movie)
    expect(resp).not_to eq(nil)
    expect(scene_details).to include(scene_data_hash)
    expect(resp.movie.to_h).to include(scene_data.movie.to_h) if scene_data.movie
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
