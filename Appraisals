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
  # >= 4.2.11.1 because CVE-2019-5420
  gem "activerecord", [">= 4.2.11.1", "< 4.3"]
  gem "database_cleaner", "~> 1.6"

  # not compatible with mysql2 0.5
  # https://github.com/brianmario/mysql2/issues/950#issuecomment-376259151
  gem "mysql2", "~> 0.4.10"

  # not compatible with pg 1.0.0
  gem "pg", "~> 0.21.0"
end

appraise "ar-5.1" do
  # >= 5.1.6.2 because CVE-2019-5420
  gem "activerecord", [">= 5.1.6.2", "< 5.2"]
  gem "rails-controller-testing", "~> 1.0.2"
end

appraise "ar-5.2" do
  # >= 5.2.2.1 because CVE-2019-5420
  gem "activerecord", [">= 5.2.2.1", "< 5.3"]
  gem "rails-controller-testing", "~> 1.0.2"
end

appraise "ar-6.0" do
  # >= 6.0.0.beta3 because CVE-2019-5420
  gem "activerecord", [">= 6.0.0.beta3", "< 6.1"]
  gem "rails-controller-testing", "~> 1.0.3"

  # Must match `gem` call in active_record/connection_adapters/sqlite3_adapter.rb
  gem "sqlite3", "~> 1.4"
end
