# Contributing

Thanks for your interest in PaperTrail!

## Reporting Security Vulnerabilities

Please email jared@jaredbeck.com and batkinz@gmail.com. Do not mention the
vulnerability publicly until there's a fix.

We will respond as soon as we can. Thank you for responsibly disclosing
security vulnerabilities.

## Usage Questions

Due to limited volunteers, we cannot answer *usage* questions. Please ask such
questions on [StackOverflow](https://stackoverflow.com/tags/paper-trail-gem).

## Reporting Bugs

You want to fix a bug, but need some help.

> You are required to provide a script that reproduces the bug, using our
> template. You are required to fix the bug. We're here to help, but no one else
> will fix it for you. If you don't fix the bug in a reasonable amount of time,
> your issue will be closed.
> - From our [issue template][1].

Due to limited volunteers, we cannot fix everyone's bugs for them. We're happy
to help, but we can only accept issues from people committed to working on their
own problems.

Different people use different parts of PaperTrail. You may have found a bug,
but you might also be the only person affected by that bug. Don't hesitate to
ask for whatever help you need, but it's your job to fix it.

## Development

```bash
gem install bundler
bundle
bundle exec appraisal install
bundle exec appraisal update # occasionally
```

Testing is a little awkward because the test suite:

1. Supports multiple versions of rails
1. Contains a "dummy" rails app with three databases (test, foo, and bar)
1. Supports three different RDBMS': sqlite, mysql, and postgres

### Test

For most development, testing with sqlite only is easiest and sufficient. CI
will run the rest.

```
DB=sqlite bundle exec appraisal rails-6.1 rake
DB=sqlite bundle exec appraisal rails-7.0 rake
DB=mysql bundle exec appraisal rails-7.0 rake
createuser --superuser postgres
DB=postgres bundle exec appraisal rails-7.0 rake
```

## The dummy_app

In the rare event you need a `console` in the `dummy_app`:

```
cd spec/dummy_app
cp config/database.mysql.yml config/database.yml
BUNDLE_GEMFILE='../../gemfiles/rails_7.0.gemfile' bin/rails console -e test
```

## Adding new schema

Edit `spec/dummy_app/db/migrate/20110208155312_set_up_test_tables.rb`. Migration
will be performed by `rake`, so you can just run it as shown above. Also,
`spec/dummy_app/db/schema.rb` is deliberately `.gitignore`d, we don't use it.

## Lowest supported ruby version

Set in three files:

- .gemspec (required_ruby_version)
- .rubocop.yml (TargetRubyVersion)
- .github/workflows/test.yml, in two places

Practically, this is only changed when dropping support for an EoL ruby version.

We `.gitignore` `.ruby-version` because it is variable, and only used by
contributors.

## Documentation

### Generate the Table of Contents

```
yarn global add markdown-toc
markdown-toc -i --maxdepth 3 --bullets='-' README.md
```

## Releases

The X-stable branches, e.g. 15-stable, are no longer maintained; not worth the
effort given that we only maintain the latest version. Ie. haven't done a
backport in a very long time.

1. Prepare release PR
  1. Checkout a new branch, eg. `release-15.1.0`
  1. Merge the relevant changes from `master`
  1. Set the version in `lib/paper_trail/version_number.rb`
  1. In the changelog,
    - Replace "Unreleased" with the date in ISO-8601 format
    - Add a new "Unreleased" section
  1. In the readme, update references to version number, including
    - list of documentation versions
    - compatability table, if necessary
  1. git commit -am 'Release 15.1.0'
  1. git push -u origin release-15.1.0
  1. Pull request into `master`, CI pass, merge PR
1. Release
  1. gem build paper_trail.gemspec
  1. gem push paper_trail-15.1.0.gem
  1. git tag -a -m "v15.1.0" "v15.1.0" # or whatever number
  1. git push --tags origin

[1]: https://github.com/paper-trail-gem/paper_trail/blob/master/.github/ISSUE_TEMPLATE/bug-report.md
