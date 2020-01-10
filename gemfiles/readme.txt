If you want to run your stuff against a specific gemfile:

Then you must set the BUNDLE_GEMFILE environment variable. Ex:
  BUNDLE_GEMFILE=gemfiles/rails_6_0.gemfile bundle exec rake test
