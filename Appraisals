# frozen_string_literal: true

# Specify here only version constraints that differ from
# `paper_trail.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

appraise "ar-4.2" do
  gem "activerecord", [">= 4.2.11.1", "< 4.3"]
  gem "database_cleaner", "~> 1.6"
  gem "mysql2", "~> 0.4.10" # not compatible with 0.5
  gem "pg", "~> 0.21.0" # not compatible with 1.0
  gem "sqlite3", "~> 1.3.13" # not compatible with 1.4
end

appraise "ar-5.1" do
  gem "activerecord", [">= 5.1.6.2", "< 5.2"]
  gem "rails-controller-testing", "~> 1.0.2"
  gem "mysql2", "~> 0.5.2"
  gem "pg", "~> 1.1"
  gem "sqlite3", "~> 1.4"
end

appraise "ar-5.2" do
  gem "activerecord", [">= 5.2.2.1", "< 5.3"]
  gem "rails-controller-testing", "~> 1.0.2"
  gem "mysql2", "~> 0.5.2"
  gem "pg", "~> 1.1"
  gem "sqlite3", "~> 1.4"
end

appraise "ar-6.0" do
  gem "activerecord", [">= 6.0.0.beta3", "<= 6.0.0.rc2"]
  gem "rails-controller-testing", "~> 1.0.3"
  gem "mysql2", "~> 0.5.2"
  gem "pg", "~> 1.1"
  gem "sqlite3", "~> 1.4"
end
