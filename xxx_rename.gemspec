# frozen_string_literal: true

require_relative "lib/xxx_rename/version"

Gem::Specification.new do |spec|
  spec.name          = "xxx_rename"
  spec.version       = XxxRename::VERSION
  spec.authors       = ["c477y"]
  spec.email         = ["c477y@pm.me"]

  spec.summary       = "Gem to rename files downloaded from porn sites"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.add_runtime_dependency "activesupport", "~> 7.0"
  spec.add_runtime_dependency "algolia", "~> 2.3"
  spec.add_runtime_dependency "awesome_print", "~> 1.9"
  spec.add_runtime_dependency "colorize", "~> 0.8.1"
  spec.add_runtime_dependency "deep_merge", "~> 1.2"
  spec.add_runtime_dependency "dry-struct"
  spec.add_runtime_dependency "dry-types"
  spec.add_runtime_dependency "dry-validation"
  spec.add_runtime_dependency "httparty", ">= 0.18.1", "< 0.22.0"
  spec.add_runtime_dependency "nokogiri", "~> 1.12"
  spec.add_runtime_dependency "rake", "~> 13.0"
  spec.add_runtime_dependency "thor", "~> 1.1"
  spec.add_development_dependency "codecov", "~> 0.6.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "rubocop", "~> 1.7"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "super_diff", "~> 0.9.0"
  spec.add_development_dependency "timecop", "~> 0.9.4"
  spec.add_development_dependency "webmock", "~> 3.14"
end
