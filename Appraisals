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
  gem "activerecord", "~> 4.2.10"
  gem "database_cleaner", "~> 1.6"
end

appraise "ar-5.0" do
  gem "activerecord", "~> 5.0.6"
  gem "rails-controller-testing"
end

appraise "ar-5.1" do
  gem "activerecord", "~> 5.1.4"
  gem "rails-controller-testing"
end

appraise "ar-5.2" do
  gem "activerecord", "~> 5.2.0.rc1"
  gem "rails-controller-testing"

  # bundler does not handle rc versions well
  # https://github.com/airblade/paper_trail/pull/1067
  # so we specify activesupport, actionpack, and railties, which we
  # would not normally do, as you can see with other rails versions above.
  gem "activesupport", "~> 5.2.0.rc1"
  gem "actionpack", "~> 5.2.0.rc1"
  gem "railties", "~> 5.2.0.rc1"
end
