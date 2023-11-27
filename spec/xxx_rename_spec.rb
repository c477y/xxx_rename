# frozen_string_literal: true

RSpec.describe XxxRename do
  it "has a version number" do
    expect(XxxRename::VERSION).not_to be nil
  end

  it "loads the project files" do
    expect { loader.eager_load(force: true) }.not_to raise_error(Zeitwerk::NameError)
  end
end
