# frozen_string_literal: true

require_relative "lib/active_record_where_assoc/version"

Gem::Specification.new do |spec|
  spec.name          = "activerecord_where_assoc"
  spec.version       = ActiveRecordWhereAssoc::VERSION
  spec.authors       = ["Maxime Handfield Lapointe"]
  spec.email         = ["maxhlap@gmail.com"]

  spec.summary       = "Make ActiveRecord do conditions on your associations"
  spec.description   = "Adds various #where_assoc_* methods to ActiveRecord to make it easy to do correct" \
                       " conditions on the associations of the model being queried."
  spec.homepage      = "https://github.com/MaxLap/activerecord_where_assoc"
  spec.license       = "MIT"

  lib_files = `git ls-files -z lib`.split("\x0")
  spec.files = [*lib_files, "CHANGELOG.md", "EXAMPLES.md", "LICENSE.txt", "README.md"]

  spec.add_dependency "activerecord", ">= 4.1.0"

  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", ">= 10.0"

  spec.add_development_dependency "deep-cover"
  spec.add_development_dependency "rubocop", "0.54.0"
  spec.add_development_dependency "simplecov"

  # Useful for the examples
  spec.add_development_dependency "niceql", ">= 0.1.23"

  # Normally, testing with sqlite3 is good enough
  spec.add_development_dependency "sqlite3"

  # Travis-CI takes care of the other ones
  # Using conditions because someone might not even be able to install the gems
  spec.add_development_dependency "pg", "< 1.0.0" if ENV["CI"] || ENV["ALL_DB"] || ["pg", "postgres", "postgresql"].include?(ENV["DB"])
end
