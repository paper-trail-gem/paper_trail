# Specify here only version constraints that differ from
# `paper_trail.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

appraise "ar3" do
  gem "activerecord", "~> 3.2.22"
  gem "i18n", "~> 0.6.11"
  gem "request_store", "~> 1.1.0"

  group :development, :test do
    gem 'railties', '~> 3.2.22'
    gem 'test-unit', '~> 3.1.5'
    platforms :ruby do
      gem 'mysql2', '~> 0.3.20'
    end
  end
end

appraise "ar4" do
  gem "activerecord", "~> 4.2"
end

appraise "ar5" do
  gem "activerecord", "~> 5.0.0"
  gem "rspec-rails", "~> 3.5.1"
  gem 'rails-controller-testing'

  # Sinatra stable conflicts with AR5's rack dependency. Sinatra master requires
  # rack-protection master. Specify exact `ref` so it doesn't break in the future.
  # Hopefully there'll be a sinatra 2.0 release soon.
  gem 'sinatra', github: 'sinatra/sinatra', ref: "a7483f48b0a18ba792e642a"
  gem "rack-protection", github: "sinatra/rack-protection", ref: "7e723a74763bb83989d12"
end
