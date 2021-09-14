name: 'Close stale items'
on:
  schedule:
    - cron: '30 1 * * *'

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v3
        with:
          stale-issue-message: >
            This issue has been automatically marked as stale due to inactivity.

            The resources of our volunteers are limited.

            Bug reports must provide a script that reproduces the bug, using
            our template. Feature suggestions must include a promise to build
            the feature yourself.

            Thank you for all your contributions.
          stale-pr-message:
            This PR has been automatically marked as stale due to inactivity.

            The resources of our volunteers are limited.

            If this is something you are committed to continue working on,
            please address any concerns raised by review and/or ping us again.

            Thank you for all your contributions.
          days-before-stale: 90
          days-before-close: 7
