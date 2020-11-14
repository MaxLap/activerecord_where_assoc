# frozen_string_literal: true

coverage_config = proc do
  add_filter "/test/"
end

if ENV["CI"]
  # No doing coverage badge at the moment.. Coveralls stopped working right after switching to
  # Github actions, and its doc is too bad for me to figure it out. A few hours lost is more
  # than I wanted to put into this.
else
  require "deep_cover"
end


require_relative "support/load_test_env"
require "minitest/autorun"
require_relative "support/custom_asserts"


class MyMinitestSpec < Minitest::Spec
  include TestHelpers

  # Annoying stuff for tests to run in transactions
  include ActiveRecord::TestFixtures
  if ActiveRecord.gem_version >= Gem::Version.new("5.0")
    self.use_transactional_tests = true
    def run_in_transaction?
      self.use_transactional_tests
    end
  else
    self.use_transactional_fixtures = true
    def run_in_transaction?
      self.use_transactional_fixtures
    end
  end

  if %w(1 true).include?(ENV["SQL_WITH_FAILURES"])
    before do
      @prev_logger = ActiveRecord::Base.logger
      @my_logged_string_io = StringIO.new
      @my_logger = Logger.new(@my_logged_string_io)
      @my_logger.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
      ActiveRecord::Base.logger = @my_logger
    end

    after do |test_case|
      ActiveRecord::Base.logger = @prev_logger
      next if test_case.passed? || test_case.skipped?

      @my_logged_string_io.rewind
      logged_lines = @my_logged_string_io.readlines

      # Ignore lines that are about the savepoints. Need to remove color codes first.
      logged_lines.reject! { |line| line.gsub(/\e\[[0-9;]*m/, "")[/\)\s*(?:RELEASE )?SAVEPOINT/i] }

      logged_string = logged_lines.join
      if logged_string.present?
        exc = test_case.failure
        orig_message = exc.message
        exc.define_singleton_method(:message) do
          "#{orig_message}\n#{logged_string}"
        end
      end
    end
  end
end

# Use my custom test case for the specs
MiniTest::Spec.register_spec_type(//, MyMinitestSpec)
