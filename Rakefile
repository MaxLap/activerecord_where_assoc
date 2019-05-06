# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

require "coveralls/rake/task"
Coveralls::RakeTask.new

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

# Not using Rake::RDocTask because it won't update things if only the stylesheet changed
desc "Generate documentation for the gem"
task :run_rdoc do
  args = ["rdoc"]
  args << "--template-stylesheets=docs_customization.css"
  args << "--title=activerecord_where_assoc"
  args << "--output=docs"
  args << "--show-hash"
  args << "lib/active_record_where_assoc/query_methods.rb"
  exit(1) unless system(*args)
end

task default: :test
