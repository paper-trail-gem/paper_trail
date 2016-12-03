# Contributing

Thanks for your interest in PaperTrail!

Ask usage questions on Stack Overflow:
https://stackoverflow.com/tags/paper-trail-gem

**Please do not use github issues to ask usage questions.**

On github, we appreciate bug reports, feature
suggestions, and especially pull requests.

Thanks, and happy (paper) trails :)

## Reporting Bugs

Please use our [bug report template][1].

## Development

Install gems with `bundle exec appraisal install`.

Testing is a little awkward because the test suite:

1. Supports multiple versions of rails
1. Contains a "dummy" rails app with three databases (test, foo, and bar)
1. Supports three different RDBMS': sqlite, mysql, and postgres

### Run tests with sqlite

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=sqlite bundle exec rake prepare

# If this is the first test run ever, create databases
cd test/dummy
RAILS_ENV=test bundle exec rake db:setup
RAILS_ENV=foo bundle exec rake db:setup
RAILS_ENV=bar bundle exec rake db:setup
cd ../..

# Run tests
DB=sqlite bundle exec appraisal ar-5.0 rake
```

### Run tests with mysql

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=mysql bundle exec rake prepare

# If this is the first test run ever, create databases
cd test/dummy
RAILS_ENV=test bundle exec rake db:setup
RAILS_ENV=foo bundle exec rake db:setup
RAILS_ENV=bar bundle exec rake db:setup
cd ../..

# Run tests
DB=mysql bundle exec appraisal ar-5.0 rake
```

### Run tests with postgres

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=postgres bundle exec rake prepare

# If this is the first test run ever, create databases.
# Unlike mysql, use create/migrate instead of setup.
cd test/dummy
DB=postgres RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
DB=postgres RAILS_ENV=foo bundle exec rake db:drop db:create db:migrate
DB=postgres RAILS_ENV=bar bundle exec rake db:drop db:create db:migrate
cd ../..

# Run tests
DB=postgres bundle exec rake
DB=postgres bundle exec appraisal ar-5.0 rake
```

## Releases

1. Set the version in lib/paper_trail/version_number.rb
  - Set PRE to nil unless it's a pre-release (beta, rc, etc.)
1. In the changelog,
  - Replace "Unreleased" with the date in iso-8601 format
  - Add a new "Unreleased" section
1. In the readme,
  - Update any other references to version number, including
  - Update version number(s) in the documentation links table
1. Commit
1. git tag -a -m "v5.0.0" "v5.0.0" # or whatever number
1. git push --tags origin 5-stable # or whatever branch
1. gem build paper_trail.gemspec
1. gem push paper_trail-5.0.0.gem

[1]: https://github.com/airblade/paper_trail/blob/master/doc/bug_report_template.rb
