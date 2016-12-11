require "rubygems"

# Set ENV['BUNDLE_GEMFILE'] as follows:
#
# Our test dummy app uses `enum`, so it must use AR >= 4.1. However, we want our
# gemspec to support AR >= 4.0. For local test runs, using our root Gemfile
# would be problematic here. For TravisCI it seems to be fine. Maybe Travis
# overwrites the root Gemfile?
if ENV.key?("BUNDLE_GEMFILE")
  # This is a local test run, and we are running rake tasks in this dummy app,
  # and we can't use the project's root Gemfile for the reasons given above.
  puts "Booting PT test dummy app: Using BUNDLE_GEMFILE: #{ENV.fetch('BUNDLE_GEMFILE')}"
else
  gemfile = File.expand_path("../../../../Gemfile", __FILE__)
  if File.exist?(gemfile)
    puts "Booting PT test dummy app: Using gemfile: #{gemfile}"
    ENV["BUNDLE_GEMFILE"] = gemfile
  end
end
require "bundler"
Bundler.setup

$LOAD_PATH.unshift(File.expand_path("../../../../lib", __FILE__))
