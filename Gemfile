# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'prime'
gem 'rails_sql_prettifier'

# Specify your gem's dependencies in active_record_where_assoc.gemspec
gemspec

# Version 2.8.0 contains sqlite 3.51.0, which has a bug: https://sqlite.org/forum/forumpost/5465c0f684
gem 'sqlite3', '!= 2.8.0'
