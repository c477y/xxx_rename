# frozen_string_literal: true

require_relative "lib/xxx_rename/version"

Gem::Specification.new do |spec|
  spec.name          = "xxx_rename"
  spec.version       = XxxRename::VERSION
  spec.authors       = ["c477y"]
  spec.email         = ["c477y@pm.me"]

  spec.summary       = "Gem to rename files downloaded from porn sites"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.add_runtime_dependency "colorize", "~> 0.8.1"
  spec.add_runtime_dependency "httparty", "~> 0.18.1"
  spec.add_runtime_dependency "thor", "~> 1.1"
end
