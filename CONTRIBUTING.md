# Contributing

Thanks for your interest in PaperTrail!

Ask usage questions on Stack Overflow:
http://stackoverflow.com/tags/papertrail

**Please do not use github issues to ask usage questions.**

On github, we appreciate bug reports, feature
suggestions, and especially pull requests.

Thanks, and happy (paper) trails :)

## Development

Run tests with sqlite:

```
bundle exec rake prepare
bundle exec rake
```

Run tests with mysql:

```
cd test/dummy
RAILS_ENV=test bundle exec rake db:setup
cd ../..
DB=mysql bundle exec rake
```
