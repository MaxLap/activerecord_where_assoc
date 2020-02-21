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
  args << "lib/active_record_where_assoc/relation_returning_methods.rb"
  args << "lib/active_record_where_assoc/sql_returning_methods.rb"

  Bundler.with_clean_env do
    exit(1) unless system(*args)
  end

  rdoc_css_path = File.join(__dir__, "docs/css/rdoc.css")
  rdoc_css = File.read(rdoc_css_path)
  # A little bug in rdoc's generated stuff... the urls in the CSS are wrong!
  rdoc_css.gsub!("url(images", "url(../images")
  File.write(rdoc_css_path, rdoc_css)

  relation_returning_methods_path = File.join(__dir__, "docs/ActiveRecordWhereAssoc/RelationReturningMethods.html")
  relation_returning_methods = File.read(relation_returning_methods_path)
  # A little bug in rdoc's generated stuff. The links to headings are broken!
  relation_returning_methods.gsub!(/#(label[^"]+)/, "#module-ActiveRecordWhereAssoc::RelationReturningMethods-\\1")
  File.write(relation_returning_methods_path, relation_returning_methods)
end

task :generate_examples do
  content = `ruby examples/examples.rb`
  if $?.success?
    File.write("EXAMPLES.md", content)
    puts "Finished generate EXAMPLES.md"
  else
    puts "Couldn't generate EXAMPLES.md"
    exit(1)
  end
end

task default: [:run_rdoc, :generate_examples, :test]
