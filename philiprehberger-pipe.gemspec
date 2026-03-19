# frozen_string_literal: true

require_relative 'lib/philiprehberger/pipe/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-pipe'
  spec.version = Philiprehberger::Pipe::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Functional pipeline composition with conditional steps and error handling'
  spec.description = 'A Ruby library for functional pipeline composition with conditional steps, ' \
                     'side effects via tee, and built-in error handling for clean data transformations.'
  spec.homepage = 'https://github.com/philiprehberger/rb-pipe'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
