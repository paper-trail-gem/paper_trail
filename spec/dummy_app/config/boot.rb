require "rubygems"

# We normally use the root project Gemfile (and gemspec), but when we run rake
# locally (not on travis) in this dummy app, we set the BUNDLE_GEMFILE env.
# variable. The project Gemfile/gemspec allows AR 4.0, which is a problem
# because this dummy app uses `enum` in some of its models, and `enum` was
# introduced in AR 4.1. So, when we run rake here, we use:
#
#     BUNDLE_GEMFILE=../../gemfiles/ar_4.2.gemfile bundle exec rake
#
# Once we drop support for AR 4.0 and 4.1 this will be less of a problem, but
# we should keep the ability to specify BUNDLE_GEMFILE because the same
# situation could come up in the future.
unless ENV.key?("BUNDLE_GEMFILE")
  gemfile = File.expand_path("../../../../Gemfile", __FILE__)
  if File.exist?(gemfile)
    puts "Booting PT test dummy app: Using gemfile: #{gemfile}"
    ENV["BUNDLE_GEMFILE"] = gemfile
  end
end
require "bundler"
Bundler.setup

$LOAD_PATH.unshift(File.expand_path("../../../../lib", __FILE__))
