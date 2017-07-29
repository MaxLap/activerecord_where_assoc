# frozen_string_literal: true

require "bundler/setup"
require "pry"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_record_where_assoc"
require "active_support"

require_relative "database_setup"
require_relative "schema"
require_relative "models"
