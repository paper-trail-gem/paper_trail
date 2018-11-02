---
name: I want to fix a bug, but need some help
about: >
  You must provide a script that reproduces the bug, using our template. We'll
  help, but you must fix the bug, in a reasonable amount of time, or your issue
  will be closed. See CONTRIBUTING.md

---

Thank you for your contribution!

Due to limited volunteers, issues that do not follow these instructions will be
closed without comment.

Check the following boxes:

- [ ] This is not a usage question, this is a bug report
- [ ] I am committed to fixing this bug myself, I just need some help
- [ ] This bug can be reproduced with the script I provide below
- [ ] This bug can be reproduced in the latest release of the `paper_trail` gem

Due to limited volunteers, we cannot answer *usage* questions. Please ask such
questions on [StackOverflow](https://stackoverflow.com/tags/paper-trail-gem).

Bug reports must use the following template:

```ruby
# frozen_string_literal: true

# Use this template to report PaperTrail bugs.
# Please include only the minimum code necessary to reproduce your issue.
require "bundler/inline"

# STEP ONE: What versions are you using?
gemfile(true) do
  ruby "2.5.1"
  source "https://rubygems.org"
  gem "activerecord", "5.2.0"
  gem "minitest", "5.11.3"
  gem "paper_trail", "9.2.0", require: false
  gem "sqlite3", "1.3.13"
end

require "active_record"
require "minitest/autorun"
require "logger"

# Please use sqlite for your bug reports, if possible.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = nil
ActiveRecord::Schema.define do
  # STEP TWO: Define your tables here.
  create_table :users, force: true do |t|
    t.text :first_name, null: false
    t.timestamps null: false
  end

  create_table :versions do |t|
    t.string :item_type, null: false
    t.integer :item_id, null: false
    t.string :event, null: false
    t.string :whodunnit
    t.text :object, limit: 1_073_741_823
    t.text :object_changes, limit: 1_073_741_823
    t.datetime :created_at
  end
  add_index :versions, %i[item_type item_id]
end
ActiveRecord::Base.logger = Logger.new(STDOUT)
require "paper_trail"

# STEP FOUR: Define your AR models here.
class User < ActiveRecord::Base
  has_paper_trail
end

# STEP FIVE: Please write a test that demonstrates your issue.
class BugTest < ActiveSupport::TestCase
  def test_1
    assert_difference(-> { PaperTrail::Version.count }, +1) {
      User.create(first_name: "Jane")
    }
  end
end

# STEP SIX: Run this script using `ruby my_bug_report.rb`
```
