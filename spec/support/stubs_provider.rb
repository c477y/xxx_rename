# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/scene_data"

shared_context "stubs provider" do
  let(:stub_scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Foo Bar", "Baz Qux"],
      male_actors: ["Fred Thud"],
      actors: ["Baz Qux", "Foo Bar", "Fred Thud"],
      collection: "Some Collection",
      collection_tag: "BZ",
      title: "Awesome Title",
      id: "1234",
      date_released: Time.local(2020, "jan", 10, 0, 0, 0)
    )
  end

  let(:stub_scene_data2) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Lorem ipsum", "dolor sit"],
      male_actors: ["consectetur adipiscing"],
      actors: ["Lorem ipsum", "dolor sit", "consectetur adipiscing"],
      collection: "sed do",
      collection_tag: "BZ",
      title: "tempor incididunt ut labore",
      date_released: Time.local(1990, "feb", 10, 0, 0, 0)
    )
  end

  let(:stub_scene_data3) do
    XxxRename::Data::SceneData.new(
      female_actors: %w[ABC DEF],
      male_actors: ["GHI"],
      actors: %w[ABC DEF GHI],
      collection: "JKL",
      collection_tag: "BZ",
      title: "MNO PQR",
      date_released: Time.local(2001, "feb", 10, 0, 0, 0)
    )
  end
end
