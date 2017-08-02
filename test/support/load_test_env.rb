# frozen_string_literal: true

require "bundler/setup"
require "pry"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_record_where_assoc"
require "active_support"

require_relative "database_setup"

TESTS_NB_DEPTH = 3
require_relative "association_genie"
require_relative "schema2"
require_relative "models2"
