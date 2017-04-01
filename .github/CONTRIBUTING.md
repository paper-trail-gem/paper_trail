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

Install gems with `bundle exec appraisal install`. This requires ruby >= 2.0.
(It is still possible to run the `ar-4.2` gemfile locally on ruby 1.9.3, but
not the `ar-5.0` gemfile.)

Testing is a little awkward because the test suite:

1. Supports multiple versions of rails
1. Contains a "dummy" rails app with three databases (test, foo, and bar)
1. Supports three different RDBMS': sqlite, mysql, and postgres

### Test sqlite, AR 4.2

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=sqlite bundle exec rake prepare

# If this is the first test run ever, create databases.
# We can't use `appraisal` inside the test dummy, so we must set `BUNDLE_GEMFILE`.
# See test/dummy/config/boot.rb for a complete explanation.
cd test/dummy
export BUNDLE_GEMFILE=../../gemfiles/ar_4.2.gemfile
RAILS_ENV=test bundle exec rake db:setup
RAILS_ENV=foo bundle exec rake db:setup
RAILS_ENV=bar bundle exec rake db:setup
unset BUNDLE_GEMFILE
cd ../..

# Run tests
DB=sqlite bundle exec appraisal ar-4.2 rake

# Run a single minitest file
DB=sqlite bundle exec appraisal ar-4.2 ruby -I test test/unit/associations_test.rb
```

### Test sqlite, AR 5

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=sqlite bundle exec rake prepare

# If this is the first test run ever, create databases.
# We can't use `appraisal` inside the test dummy, so we must set `BUNDLE_GEMFILE`.
# See test/dummy/config/boot.rb for a complete explanation.
cd test/dummy
export BUNDLE_GEMFILE=../../gemfiles/ar_5.0.gemfile
RAILS_ENV=test bundle exec rake db:environment:set db:setup
RAILS_ENV=foo bundle exec rake db:environment:set db:setup
RAILS_ENV=bar bundle exec rake db:environment:set db:setup
unset BUNDLE_GEMFILE
cd ../..

# Run tests
DB=sqlite bundle exec appraisal ar-5.0 rake
```

### Test mysql, AR 5

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=mysql bundle exec rake prepare

# If this is the first test run ever, create databases.
# We can't use `appraisal` inside the test dummy, so we must set `BUNDLE_GEMFILE`.
# See test/dummy/config/boot.rb for a complete explanation.
cd test/dummy
export BUNDLE_GEMFILE=../../gemfiles/ar_5.0.gemfile
RAILS_ENV=test bundle exec rake db:environment:set db:setup
RAILS_ENV=foo bundle exec rake db:environment:set db:setup
RAILS_ENV=bar bundle exec rake db:environment:set db:setup
unset BUNDLE_GEMFILE
cd ../..

# Run tests
DB=mysql bundle exec appraisal ar-5.0 rake
```

### Test postgres, AR 5

```
# Create the appropriate database config. file
rm test/dummy/config/database.yml
DB=postgres bundle exec rake prepare

# If this is the first test run ever, create databases.
# Unlike mysql, use create/migrate instead of setup.
# We can't use `appraisal` inside the test dummy, so we must set `BUNDLE_GEMFILE`.
# See test/dummy/config/boot.rb for a complete explanation.
cd test/dummy
export BUNDLE_GEMFILE=../../gemfiles/ar_5.0.gemfile
DB=postgres RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
DB=postgres RAILS_ENV=foo bundle exec rake db:drop db:create db:migrate
DB=postgres RAILS_ENV=bar bundle exec rake db:drop db:create db:migrate
unset BUNDLE_GEMFILE
cd ../..

# Run tests
DB=postgres bundle exec rake
DB=postgres bundle exec appraisal ar-5.0 rake
```

## Editing the migration

After editing `test/dummy/db/migrate/20110208155312_set_up_test_tables.rb` ..

```
cd test/dummy
export BUNDLE_GEMFILE=../../gemfiles/ar_5.0.gemfile
RAILS_ENV=test bundle exec rake db:environment:set db:drop db:create db:migrate
RAILS_ENV=foo bundle exec rake db:environment:set db:drop db:create db:migrate
RAILS_ENV=bar bundle exec rake db:environment:set db:drop db:create db:migrate
unset BUNDLE_GEMFILE
cd ../..
```

Don't forget to commit changes to `schema.rb`.

## Releases

1. Set the version in lib/paper_trail/version_number.rb
  - Set PRE to nil unless it's a pre-release (beta, rc, etc.)
1. In the changelog,
  - Replace "Unreleased" with the date in iso-8601 format
  - Add a new "Unreleased" section
1. In the readme, update references to version number, including
  - documentation links table
  - compatability table
1. Commit
1. git tag -a -m "v5.0.0" "v5.0.0" # or whatever number
1. git push --tags origin 5-stable # or whatever branch
1. gem build paper_trail.gemspec
1. gem push paper_trail-5.0.0.gem

[1]: https://github.com/airblade/paper_trail/blob/master/doc/bug_report_template.rb
