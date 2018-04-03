# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record_where_assoc/version"

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

  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md"]

  spec.add_dependency "activerecord", ">= 4.1.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "simplecov"

  # Normally, testing with sqlite3 is good enough
  spec.add_development_dependency "sqlite3"

  # Travis-CI takes care of the other ones
  # Using conditions because someone might not even be able to install the gems
  spec.add_development_dependency "mysql2", "~> 0.4.0" if ENV["TRAVIS"] || ENV["ALL_DB"] || ENV["DB"] == "mysql"
  spec.add_development_dependency "pg", "< 1.0.0" if ENV["TRAVIS"] || ENV["ALL_DB"] || ENV["DB"] == "pg"
end
