# frozen_string_literal: true

require "active_support/core_ext/hash/except"

# A custom matcher designed specifically for XxxRename::Data::SceneData
# This matcher will bypass checks on certain keys in scene_data
# Keys like `movie.synopsis` are not matched as they can be arbitrary
# and add extra effort to write in specs
RSpec::Matchers.define :eq_scene_data do |expected|
  match do |actual|
    unless expected.class.to_s == "XxxRename::Data::SceneData"
      raise ArgumentError, "wrong argument type for expected (given #{expected.class}, expected XxxRename::Data::SceneData"
    end

    unless actual.class.to_s == "XxxRename::Data::SceneData"
      raise ArgumentError, "wrong argument type for actual (given #{actual.class}, expected XxxRename::Data::SceneData"
    end

    expected_root_keys = expected.to_h.except(:movie, :original_filenames).compact
    actual_root_keys = actual.to_h.except(:movie, :original_filenames).compact
    expect(expected_root_keys).to eq(actual_root_keys)

    expected_movie_key = expected.to_h&.[](:movie)&.except(:synopsis)&.compact
    actual_movie_key = actual.to_h&.[](:movie)&.except(:synopsis)&.compact
    expect(expected_movie_key).to eq(actual_movie_key)
  end
end
