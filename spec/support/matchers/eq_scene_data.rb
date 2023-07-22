# frozen_string_literal: true

require "active_support/core_ext/hash/except"

# A custom matcher designed specifically for XxxRename::Data::SceneData
# This matcher will bypass checks on certain keys in scene_data
# Keys like `movie.synopsis` are not matched as they can be arbitrary
# and add extra effort to write in specs
RSpec::Matchers.define :eq_scene_data do |expected|
  def compare(expected, actual)
    scene_ignored_keys = %i[movie description]
    movie_ignored_keys = %i[synopsis]
    expected_root_keys = expected.to_h.except(*scene_ignored_keys).compact
    actual_root_keys = actual.to_h.except(*scene_ignored_keys).compact
    expect(expected_root_keys).to eq(actual_root_keys)

    expected_movie_key = expected.to_h&.[](:movie)&.except(*movie_ignored_keys)&.compact
    actual_movie_key = actual.to_h&.[](:movie)&.except(*movie_ignored_keys)&.compact
    expect(expected_movie_key).to eq(actual_movie_key)
  end

  match do |actual|
    unless expected.instance_of?(XxxRename::Data::SceneData)
      raise ArgumentError, "wrong argument type for expected (given #{expected.class}, expected XxxRename::Data::SceneData"
    end

    unless actual.instance_of?(XxxRename::Data::SceneData)
      raise ArgumentError, "wrong argument type for actual (given #{actual.class}, expected XxxRename::Data::SceneData"
    end

    compare(expected, actual)
  end

  failure_message do |actual|
    compare(expected, actual)
  end
end
