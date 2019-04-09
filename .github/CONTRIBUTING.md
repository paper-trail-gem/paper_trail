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

Install gems with `bundle exec appraisal install`.

Testing is a little awkward because the test suite:

1. Supports multiple versions of rails
1. Contains a "dummy" rails app with three databases (test, foo, and bar)
1. Supports three different RDBMS': sqlite, mysql, and postgres

### Test sqlite, AR 4

```
DB=sqlite bundle exec appraisal ar-4.2 rake

# Run a single test
DB=sqlite bundle exec appraisal ar-4.2 rspec spec/paper_trail_spec.rb
```

### Test sqlite, AR 5

```
DB=sqlite bundle exec appraisal ar-5.2 rake
```

### Test mysql, AR 5

```
DB=mysql bundle exec appraisal ar-5.2 rake
```

### Test postgres, AR 5

```
createuser --superuser postgres
DB=postgres bundle exec appraisal ar-5.2 rake
```

## Adding new schema

Edit `spec/dummy_app/db/migrate/20110208155312_set_up_test_tables.rb`. Migration
will be performed by `rake`, so you can just run it as shown above. Also,
`spec/dummy_app/db/schema.rb` is deliberately `.gitignore`d, we don't use it.

## Documentation

### Generate the Table of Contents

```
yarn global add markdown-toc
markdown-toc -i --maxdepth 3 --bullets='-' README.md
```

## Releases

1. Prepare the appropriate "stable" branch for release, eg. `10-stable`
  1. git checkout 10-stable
  1. Checkout a new branch, eg. `release-10.3.0`
  1. Merge the relevant changes from `master`. This could be a plain merge, or
    it could be cherry-picking. The later is more common in backports.
  1. Set the version in `lib/paper_trail/version_number.rb`
  1. In the changelog,
    - Replace "Unreleased" with the date in ISO-8601 format
    - Add a new "Unreleased" section
  1. In the readme, update references to version number, including
    - documentation links table
    - compatability table, if necessary
  1. git commit -am 'Release 10.3.0'
  1. git push origin release-10.3.0
  1. Pull request into `10-stable`, CI pass, merge PR
1. Release
  1. git checkout 10-stable && git pull
  1. gem build paper_trail.gemspec
  1. gem push paper_trail-10.3.0.gem
  1. git tag -a -m "v10.3.0" "v10.3.0" # or whatever number
  1. git push --tags origin
1. Cleanup
  1. git checkout master
  1. cherry-pick the "Release 10.3.0" commit from the `10-stable` branch
  1. git push origin master

[1]: https://github.com/paper-trail-gem/paper_trail/blob/master/.github/ISSUE_TEMPLATE/bug_report.md
