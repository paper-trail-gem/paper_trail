# Specify here only version constraints that differ from
# `paper_trail.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don"t need to repeat anything that"s the same for each
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
  gem "activerecord", "5.0.0.beta1"
  gem "activemodel", "5.0.0.beta1"
  gem "actionpack", "5.0.0.beta1"
  gem "railties", "5.0.0.beta1"
  gem "rspec-rails", github: "rspec/rspec-rails"
  gem "rspec-core", github: "rspec/rspec-core"
  gem "rspec-expectations", github: "rspec/rspec-expectations"
  gem "rspec-mocks", github: "rspec/rspec-mocks"
  gem "rspec-support", github: "rspec/rspec-support"
  gem 'rails-controller-testing'
  # Sinatra stable conflicts with AR5's rack dependency
  gem 'sinatra', github: 'sinatra/sinatra'
end
