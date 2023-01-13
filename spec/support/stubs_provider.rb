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
end
