# PaperTrail

[![Build Status][4]][5] [![Dependency Status][6]][7]

Track changes to your models, for auditing or versioning. See how a model looked
at any stage in its lifecycle, revert it to any version, or restore it after it
has been destroyed.

## Documentation

| Version        | Documentation |
| -------------- | ------------- |
| Unreleased     | https://github.com/airblade/paper_trail/blob/master/README.md |
| 7.1.3          | https://github.com/airblade/paper_trail/blob/v7.1.3/README.md |
| 6.0.2          | https://github.com/airblade/paper_trail/blob/v6.0.2/README.md |
| 5.2.3          | https://github.com/airblade/paper_trail/blob/v5.2.3/README.md |
| 4.2.0          | https://github.com/airblade/paper_trail/blob/v4.2.0/README.md |
| 3.0.9          | https://github.com/airblade/paper_trail/blob/v3.0.9/README.md |
| 2.7.2          | https://github.com/airblade/paper_trail/blob/v2.7.2/README.md |
| 1.6.5          | https://github.com/airblade/paper_trail/blob/v1.6.5/README.md |

## Table of Contents

- [1. Introduction](#1-introduction)
  - [1.a. Compatibility](#1a-compatibility)
  - [1.b. Installation](#1b-installation)
  - [1.c. Basic Usage](#1c-basic-usage)
  - [1.d. API Summary](#1d-api-summary)
  - [1.e. Configuration](#1e-configuration)
- [2. Limiting What is Versioned, and When](#2-limiting-what-is-versioned-and-when)
  - [2.a. Choosing Lifecycle Events To Monitor](#2a-choosing-lifecycle-events-to-monitor)
  - [2.b. Choosing When To Save New Versions](#2b-choosing-when-to-save-new-versions)
  - [2.c. Choosing Attributes To Monitor](#2c-choosing-attributes-to-monitor)
  - [2.d. Turning PaperTrail Off](#2d-turning-papertrail-off)
  - [2.e. Limiting the Number of Versions Created](#2e-limiting-the-number-of-versions-created)
- [3. Working With Versions](#3-working-with-versions)
  - [3.a. Reverting And Undeleting A Model](#3a-reverting-and-undeleting-a-model)
  - [3.b. Navigating Versions](#3b-navigating-versions)
  - [3.c. Diffing Versions](#3c-diffing-versions)
  - [3.d. Deleting Old Versions](#3d-deleting-old-versions)
- [4. Saving More Information About Versions](#4-saving-more-information-about-versions)
  - [4.a. Finding Out Who Was Responsible For A Change](#4a-finding-out-who-was-responsible-for-a-change)
  - [4.b. Associations](#4b-associations)
    - [4.b.1. Known Issues](#4b1-known-issues)
  - [4.c. Storing metadata](#4c-storing-metadata)
- [5. ActiveRecord](#5-activerecord)
  - [5.a. Single Table Inheritance](#5a-single-table-inheritance-sti)
  - [5.b. Configuring the `versions` Association](#5b-configuring-the-versions-association)
  - [5.c. Generators](#5c-generators)
  - [5.d. Protected Attributes](#5d-protected-attributes)
- [6. Extensibility](#6-extensibility)
  - [6.a. Custom Version Classes](#6a-custom-version-classes)
  - [6.b. Custom Serializer](#6b-custom-serializer)
- [7. Testing](#7-testing)
  - [7.a Minitest](#7a-minitest)
  - [7.b RSpec](#7b-rspec)
  - [7.c Cucumber](#7c-cucumber)
  - [7.d Spork](#7d-spork)
  - [7.e Zeus or Spring](#7e-zeus-or-spring)
- [8. Integration with Other Libraries](#8-integration-with-other-libraries)

## 1. Introduction

### 1.a. Compatibility

| paper_trail    | branch     | tags   | ruby     | activerecord  |
| -------------- | ---------- | ------ | -------- | ------------- |
| unreleased     | master     |        | >= 2.1.0 | >= 4.0, < 6   |
| 7              | 7-stable   | v7.x   | >= 2.1.0 | >= 4.0, < 6   |
| 6              | 6-stable   | v6.x   | >= 1.9.3 | >= 4.0, < 6   |
| 5              | 5-stable   | v5.x   | >= 1.9.3 | >= 3.0, < 5.1 |
| 4              | 4-stable   | v4.x   | >= 1.8.7 | >= 3.0, < 5.1 |
| 3              | 3.0-stable | v3.x   | >= 1.8.7 | >= 3.0, < 5   |
| 2              | 2.7-stable | v2.x   | >= 1.8.7 | >= 3.0, < 4   |
| 1              | rails2     | v1.x   | >= 1.8.7 | >= 2.3, < 3   |

### 1.b. Installation

1. Add PaperTrail to your `Gemfile`.

    `gem 'paper_trail'`

1. Add a `versions` table to your database and an initializer file for configuration:

    ```
    bundle exec rails generate paper_trail:install
    bundle exec rake db:migrate
    ```

    If using [rails_admin][38], you must enable the experimental
    [Associations](#4b-associations) feature. For more information on this
    generator, see [section 5.c. Generators](#5c-generators).

1. Add `has_paper_trail` to the models you want to track.

    ```ruby
    class Widget < ActiveRecord::Base
      has_paper_trail
    end
    ```

1. If your controllers have a `current_user` method, you can easily [track who
is responsible for changes](#4a-finding-out-who-was-responsible-for-a-change)
by adding a controller callback.

    ```ruby
    class ApplicationController
      before_action :set_paper_trail_whodunnit
    end
    ```

### 1.c. Basic Usage

Your models now have a `versions` method which returns the "paper trail" of
changes to your model.

```ruby
widget = Widget.find 42
widget.versions
# [<PaperTrail::Version>, <PaperTrail::Version>, ...]
```

Once you have a version, you can find out what happened:

```ruby
v = widget.versions.last
v.event                     # 'update', 'create', or 'destroy'
v.created_at                # When the `event` occurred
v.whodunnit                 # If the update was via a controller and the
                            # controller has a current_user method, returns the
                            # id of the current user as a string.
widget = v.reify            # The widget as it was before the update
                            # (nil for a create event)
```

PaperTrail stores the pre-change version of the model, unlike some other
auditing/versioning plugins, so you can retrieve the original version.  This is
useful when you start keeping a paper trail for models that already have records
in the database.

```ruby
widget = Widget.find 153
widget.name                                 # 'Doobly'

# Add has_paper_trail to Widget model.

widget.versions                             # []
widget.update_attributes name: 'Wotsit'
widget.versions.last.reify.name             # 'Doobly'
widget.versions.last.event                  # 'update'
```

This also means that PaperTrail does not waste space storing a version of the
object as it currently stands.  The `versions` method gives you previous
versions; to get the current one just call a finder on your `Widget` model as
usual.

Here's a helpful table showing what PaperTrail stores:

| *Event*        | *create* | *update* | *destroy* |
| -------------- | -------- | -------- | --------- |
| *Model Before* | nil      | widget   | widget    |
| *Model After*  | widget   | widget   | nil       |

PaperTrail stores the values in the Model Before column.  Most other
auditing/versioning plugins store the After column.

### 1.d. API Summary

When you declare `has_paper_trail` in your model, you get these methods:

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail
end

# Returns this widget's versions.  You can customise the name of the
# association, but overriding this method is not supported.
widget.versions

# Return the version this widget was reified from, or nil if it is live.
# You can customise the name of the method.
widget.version

# Returns true if this widget is the current, live one; or false if it is from
# a previous version.
widget.paper_trail.live?

# Returns who put the widget into its current state.
widget.paper_trail.originator

# Returns the widget (not a version) as it looked at the given timestamp.
widget.paper_trail.version_at(timestamp)

# Returns the widget (not a version) as it was most recently.
widget.paper_trail.previous_version

# Returns the widget (not a version) as it became next.
widget.paper_trail.next_version

# Generates a version for a `touch` event (`widget.touch` does NOT generate a
# version)
widget.paper_trail.touch_with_version

# Turn PaperTrail off for all widgets.
Widget.paper_trail.disable

# Turn PaperTrail on for all widgets.
Widget.paper_trail.enable

# Is PaperTrail enabled for Widget, the class?
Widget.paper_trail.enabled?

# Is PaperTrail enabled for widget, the instance?
widget.paper_trail.enabled_for_model?
```

And a `PaperTrail::Version` instance (which is just an ordinary ActiveRecord
instance, with all the usual methods) adds these methods:

```ruby
# Returns the item restored from this version.
version.reify(options = {})

# Return a new item from this version
version.reify(dup: true)

# Returns who put the item into the state stored in this version.
version.paper_trail_originator

# Returns who changed the item from the state it had in this version.
version.terminator
version.whodunnit
version.version_author

# Returns the next version.
version.next

# Returns the previous version.
version.previous

# Returns the index of this version in all the versions.
version.index

# Returns the event that caused this version (create|update|destroy).
version.event

# Query the `versions.object` column (or `object_changes` column), by
# attributes, using the SQL LIKE operator. Known issue: inconsistent results for
# numeric values due to limitations of SQL wildcard matchers against the
# serialized objects.
PaperTrail::Version.where_object(attr1: val1, attr2: val2)
PaperTrail::Version.where_object_changes(attr1: val1)
```

In your controllers you can override these methods:

```ruby
# Returns the user who is responsible for any changes that occur.
# Defaults to current_user.
user_for_paper_trail

# Returns any information about the controller or request that you want
# PaperTrail to store alongside any changes that occur.
info_for_paper_trail
```

### 1.e. Configuration

Many aspects of PaperTrail are configurable for individual models; typically
this is achieved by passing options to the `has_paper_trail` method within
a given model.

Some aspects of PaperTrail are configured globally for all models. These
settings are assigned directly on the `PaperTrail.config` object.
A common place to put these settings is in a Rails initializer file
such as `config/initializers/paper_trail.rb` or in an environment-specific
configuration file such as `config/environments/test.rb`.

## 2. Limiting What is Versioned, and When

### 2.a. Choosing Lifecycle Events To Monitor

You can choose which events to track with the `on` option.  For example, to
ignore `create` events:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail on: [:update, :destroy]
end
```

`has_paper_trail` installs callbacks for these lifecycle events. If there are
other callbacks in your model, their order relative to those installed by
PaperTrail may matter, so be aware of any potential interactions.

You may also have the `PaperTrail::Version` model save a custom string in its
`event` field instead of the typical `create`, `update`, `destroy`. PaperTrail
supplies a custom accessor method called `paper_trail_event`, which it will
attempt to use to fill the `event` field before falling back on one of the
default events.

```ruby
a = Article.create
a.versions.size                           # 1
a.versions.last.event                     # 'create'
a.paper_trail_event = 'update title'
a.update_attributes title: 'My Title'
a.versions.size                           # 2
a.versions.last.event                     # 'update title'
a.paper_trail_event = nil
a.update_attributes title: 'Alternate'
a.versions.size                           # 3
a.versions.last.event                     # 'update'
```

#### Controlling the Order of AR Callbacks

The `has_paper_trail` method installs AR callbacks. If you need to control
their order, use the `paper_trail_on_*` methods.

```ruby
class Article < ActiveRecord::Base

  # Include PaperTrail, but do not add any callbacks yet. Passing the
  # empty array to `:on` omits callbacks.
  has_paper_trail on: []

  # Add callbacks in the order you need.
  paper_trail.on_destroy    # add destroy callback
  paper_trail.on_update     # etc.
  paper_trail.on_create
end
```

The `paper_trail.on_destroy` method can be further configured to happen
`:before` or `:after` the destroy event. In PaperTrail 4, the default is
`:after`. In PaperTrail 5, the default will be `:before`, to support
ActiveRecord 5. (see https://github.com/airblade/paper_trail/pull/683)

### 2.b. Choosing When To Save New Versions

You can choose the conditions when to add new versions with the `if` and
`unless` options. For example, to save versions only for US non-draft
translations:

```ruby
class Translation < ActiveRecord::Base
  has_paper_trail if:     Proc.new { |t| t.language_code == 'US' },
                  unless: Proc.new { |t| t.type == 'DRAFT'       }
end
```

#### Choosing Based on Changed Attributes

Starting with PaperTrail 4.0, versions are saved during an after-callback. If
you decide whether to save a new version based on changed attributes, please
use attribute_name_was instead of attribute_name.

### 2.c. Choosing Attributes To Monitor

#### Ignore

You can `ignore` changes to certain attributes:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail ignore: [:title, :rating]
end
```

Changes to just the `title` or `rating` will not create a version record.
Changes to other attributes will create a version record.

```ruby
a = Article.create
a.versions.length                         # 1
a.update_attributes title: 'My Title', rating: 3
a.versions.length                         # 1
a.update_attributes title: 'Greeting', content: 'Hello'
a.versions.length                         # 2
a.paper_trail.previous_version.title      # 'My Title'
```

#### Only

Or, you can specify a list of the `only` attributes you care about:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail only: [:title]
end
```

Only changes to the `title` will create a version record.

```ruby
a = Article.create
a.versions.length                         # 1
a.update_attributes title: 'My Title'
a.versions.length                         # 2
a.update_attributes content: 'Hello'
a.versions.length                         # 2
a.paper_trail.previous_version.content    # nil
```

The `:ignore` and `:only` options can also accept `Hash` arguments.

```ruby
class Article < ActiveRecord::Base
  has_paper_trail only: { title: Proc.new { |obj| !obj.title.blank? } }
end
```

If the `title` is not blank, then only changes to the `title`
will create a version record.

```ruby
a = Article.create
a.versions.length                         # 1
a.update_attributes content: 'Hello'
a.versions.length                         # 2
a.update_attributes title: 'Title One'
a.versions.length                         # 3
a.update_attributes content: 'Hai'
a.versions.length                         # 3
a.paper_trail.previous_version.content    # "Hello"
a.update_attributes title: 'Title Two'
a.versions.length                         # 4
a.paper_trail.previous_version.content    # "Hai"
```

Configuring both `:ignore` and `:only` is not recommended, but it should work as
expected. Passing both `:ignore` and `:only` options will result in the
article being saved if a changed attribute is included in `:only` but not in
`:ignore`.

#### Skip

You can skip attributes completely with the `:skip` option.  As with `:ignore`,
updates to these attributes will not create a version record.  In addition, if a
version record is created for some other reason, these attributes will not be
persisted.

```ruby
class Article < ActiveRecord::Base
  has_paper_trail skip: [:file_upload]
end
```

### 2.d. Turning PaperTrail Off

PaperTrail is on by default, but sometimes you don't want to record versions.

#### Per Process

Turn PaperTrail off for all threads in a `ruby` process.

```ruby
PaperTrail.enabled = false
```

This is commonly used to speed up tests. See [Testing](#7-testing) below.

There is also a rails config option that does the same thing.

```ruby
# in config/environments/test.rb
config.paper_trail.enabled = false
```

#### Per Request

Add a `paper_trail_enabled_for_controller` method to your controller.

```ruby
class ApplicationController < ActionController::Base
  def paper_trail_enabled_for_controller
    request.user_agent != 'Disable User-Agent'
  end
end
```

#### Per Class

```ruby
Widget.paper_trail.disable
Widget.paper_trail.enable
```

#### Per Method

You can call a method without creating a new version using `without_versioning`.
 It takes either a method name as a symbol:

```ruby
@widget.paper_trail.without_versioning :destroy
```

Or a block:

```ruby
@widget.paper_trail.without_versioning do
  @widget.update_attributes name: 'Ford'
end
```

PaperTrail is disabled for the whole model
(e.g. `Widget`), not just for the instance (e.g. `@widget`).

### 2.e. Limiting the Number of Versions Created

Configure `version_limit` to cap the number of versions saved per record. This
does not apply to `create` events.

```ruby
# Limit: 4 versions per record (3 most recent, plus a `create` event)
PaperTrail.config.version_limit = 3
# Remove the limit
PaperTrail.config.version_limit = nil
```

## 3. Working With Versions

### 3.a. Reverting And Undeleting A Model

PaperTrail makes reverting to a previous version easy:

```ruby
widget = Widget.find 42
widget.update_attributes name: 'Blah blah'
# Time passes....
widget = widget.paper_trail.previous_version  # the widget as it was before the update
widget.save                                   # reverted
```

Alternatively you can find the version at a given time:

```ruby
widget = widget.paper_trail.version_at(1.day.ago)  # the widget as it was one day ago
widget.save                                        # reverted
```

Note `version_at` gives you the object, not a version, so you don't need to call
`reify`.

Undeleting is just as simple:

```ruby
widget = Widget.find(42)
widget.destroy
# Time passes....
versions = widget.versions    # versions ordered by versions.created_at, ascending
widget = versions.last.reify  # the widget as it was before destruction
widget.save                   # the widget lives!
```

You could even use PaperTrail to implement an undo system; [Ryan Bates has!][3]

If your model uses [optimistic locking][1] don't forget to [increment your
`lock_version`][2] before saving or you'll get a `StaleObjectError`.

### 3.b. Navigating Versions

You can call `previous_version` and `next_version` on an item to get it as it
was/became.  Note that these methods reify the item for you.

```ruby
live_widget = Widget.find 42
live_widget.versions.length                       # 4, for example
widget = live_widget.paper_trail.previous_version # => widget == live_widget.versions.last.reify
widget = widget.paper_trail.previous_version      # => widget == live_widget.versions[-2].reify
widget = widget.paper_trail.next_version          # => widget == live_widget.versions.last.reify
widget.paper_trail.next_version                   # live_widget
```

If instead you have a particular `version` of an item you can navigate to the
previous and next versions.

```ruby
widget = Widget.find 42
version = widget.versions[-2]    # assuming widget has several versions
previous = version.previous
next = version.next
```

You can find out which of an item's versions yours is:

```ruby
current_version_number = version.index    # 0-based
```

If you got an item by reifying one of its versions, you can navigate back to the
version it came from:

```ruby
latest_version = Widget.find(42).versions.last
widget = latest_version.reify
widget.version == latest_version    # true
```

You can find out whether a model instance is the current, live one -- or whether
it came instead from a previous version -- with `live?`:

```ruby
widget = Widget.find 42
widget.live?                        # true
widget = widget.paper_trail.previous_version
widget.live?                        # false
```

And you can perform `WHERE` queries for object versions based on attributes:

```ruby
# All versions that meet these criteria.
PaperTrail::Version.where_object(content: 'Hello', title: 'Article')
```

### 3.c. Diffing Versions

There are two scenarios: diffing adjacent versions and diffing non-adjacent
versions.

The best way to diff adjacent versions is to get PaperTrail to do it for you.
If you add an `object_changes` text column to your `versions` table, either at
installation time with the `rails generate paper_trail:install --with-changes`
option or manually, PaperTrail will store the `changes` diff (excluding any
attributes PaperTrail is ignoring) in each `update` version.  You can use the
`version.changeset` method to retrieve it.  For example:

```ruby
widget = Widget.create name: 'Bob'
widget.versions.last.changeset
# {
#   "name"=>[nil, "Bob"],
#   "created_at"=>[nil, 2015-08-10 04:10:40 UTC],
#   "updated_at"=>[nil, 2015-08-10 04:10:40 UTC],
#   "id"=>[nil, 1]
# }
widget.update_attributes name: 'Robert'
widget.versions.last.changeset
# {
#   "name"=>["Bob", "Robert"],
#   "updated_at"=>[2015-08-10 04:13:19 UTC, 2015-08-10 04:13:19 UTC]
# }
widget.destroy
widget.versions.last.changeset
# {}
```

The `object_changes` are only stored for creation and updates, not when an
object is destroyed.

Please be aware that PaperTrail doesn't use diffs internally.  When I designed
PaperTrail I wanted simplicity and robustness so I decided to make each version
of an object self-contained.  A version stores all of its object's data, not a
diff from the previous version.  This means you can delete any version without
affecting any other.

To diff non-adjacent versions you'll have to write your own code.  These
libraries may help:

For diffing two strings:

* [htmldiff][19]: expects but doesn't require HTML input and produces HTML
  output.  Works very well but slows down significantly on large (e.g. 5,000
  word) inputs.
* [differ][20]: expects plain text input and produces plain
  text/coloured/HTML/any output.  Can do character-wise, word-wise, line-wise,
  or arbitrary-boundary-string-wise diffs.  Works very well on non-HTML input.
* [diff-lcs][21]: old-school, line-wise diffs.

For diffing two ActiveRecord objects:

* [Jeremy Weiskotten's PaperTrail fork][22]: uses ActiveSupport's diff to return
  an array of hashes of the changes.
* [activerecord-diff][23]: rather like ActiveRecord::Dirty but also allows you
  to specify which columns to compare.

If you want to selectively record changes for some models but not others you
can opt out of recording changes by passing `save_changes: false` to your
`has_paper_trail` method declaration.

### 3.d. Deleting Old Versions

Over time your `versions` table will grow to an unwieldy size.  Because each
version is self-contained (see the Diffing section above for more) you can
simply delete any records you don't want any more.  For example:

```sql
sql> delete from versions where created_at < 2010-06-01;
```

```ruby
PaperTrail::Version.delete_all ['created_at < ?', 1.week.ago]
```

## 4. Saving More Information About Versions

### 4.a. Finding Out Who Was Responsible For A Change

Set `PaperTrail.whodunnit=`, and that value will be stored in the version's
`whodunnit` column.

```ruby
PaperTrail.whodunnit = 'Andy Stewart'
widget.update_attributes name: 'Wibble'
widget.versions.last.whodunnit              # Andy Stewart
```

`whodunnit` also accepts a block, a convenient way to temporarily set the value.

```ruby
PaperTrail.whodunnit('Dorian Marié') do
  widget.update_attributes name: 'Wibble'
end
```

`whodunnit` also accepts a `Proc`.

```ruby
PaperTrail.whodunnit = proc do
  caller.first{ |c| c.starts_with? Rails.root.to_s }
end
```

If your controller has a `current_user` method, PaperTrail provides a
`before_action` that will assign `current_user.id` to `PaperTrail.whodunnit`.
You can add this `before_action` to your `ApplicationController`.

```ruby
class ApplicationController
  before_action :set_paper_trail_whodunnit
end
```

You may want `set_paper_trail_whodunnit` to call a different method to find out
who is responsible. To do so, override the `user_for_paper_trail` method in
your controller like this:

```ruby
class ApplicationController
  def user_for_paper_trail
    logged_in? ? current_member.id : 'Public user'  # or whatever
  end
end
```

See also: [Setting whodunnit in the rails console][33]

Sometimes you want to define who is responsible for a change in a small scope
without overwriting value of `PaperTrail.whodunnit`. It is possible to define
the `whodunnit` value for an operation inside a block like this:

```ruby
PaperTrail.whodunnit = 'Andy Stewart'
widget.paper_trail.whodunnit('Lucas Souza') do
  widget.update_attributes name: 'Wibble'
end
widget.versions.last.whodunnit              # Lucas Souza
widget.update_attributes name: 'Clair'
widget.versions.last.whodunnit              # Andy Stewart
```

A version's `whodunnit` records who changed the object causing the `version` to
be stored.  Because a version stores the object as it looked before the change
(see the table above), `whodunnit` returns who stopped the object looking like
this -- not who made it look like this.  Hence `whodunnit` is aliased as
`terminator`.

To find out who made a version's object look that way, use
`version.paper_trail_originator`.  And to find out who made a "live" object look
like it does, call `paper_trail_originator` on the object.

```ruby
widget = Widget.find 153                    # assume widget has 0 versions
PaperTrail.whodunnit = 'Alice'
widget.update_attributes name: 'Yankee'
widget.paper_trail.originator               # 'Alice'
PaperTrail.whodunnit = 'Bob'
widget.update_attributes name: 'Zulu'
widget.paper_trail.originator               # 'Bob'
first_version, last_version = widget.versions.first, widget.versions.last
first_version.whodunnit                     # 'Alice'
first_version.paper_trail_originator        # nil
first_version.terminator                    # 'Alice'
last_version.whodunnit                      # 'Bob'
last_version.paper_trail_originator         # 'Alice'
last_version.terminator                     # 'Bob'
```

#### Storing an ActiveRecord globalid in whodunnit

If you would like `whodunnit` to return an `ActiveRecord` object instead of a
string, please try the [paper_trail-globalid][37] gem.

### 4.b. Associations

**Experimental feature**, not recommended for production. See known issues
below.

PaperTrail can restore three types of associations: Has-One, Has-Many, and
Has-Many-Through. In order to do this, you will need to do two things:

1. Create a `version_associations` table
2. Set `PaperTrail.config.track_associations = true` (e.g. in an initializer)

Both will be done for you automatically if you install PaperTrail with the
`--with_associations` option
(e.g. `rails generate paper_trail:install --with-associations`)

If you want to add this functionality after the initial installation, you will
need to create the `version_associations` table manually, and you will need to
ensure that `PaperTrail.config.track_associations = true` is set.

PaperTrail will store in the `version_associations` table additional information
to correlate versions of the association and versions of the model when the
associated record is changed. When reifying the model, PaperTrail can use this
table, together with the `transaction_id` to find the correct version of the
association and reify it. The `transaction_id` is a unique id for version records
created in the same transaction. It is used to associate the version of the model
and the version of the association that are created in the same transaction.

To restore Has-One associations as they were at the time, pass option `has_one:
true` to `reify`. To restore Has-Many and Has-Many-Through associations, use
option `has_many: true`. To restore Belongs-To association, use
option `belongs_to: true`. For example:

```ruby
class Location < ActiveRecord::Base
  belongs_to :treasure
  has_paper_trail
end

class Treasure < ActiveRecord::Base
  has_one :location
  has_paper_trail
end

treasure.amount                  # 100
treasure.location.latitude       # 12.345

treasure.update_attributes amount: 153
treasure.location.update_attributes latitude: 54.321

t = treasure.versions.last.reify(has_one: true)
t.amount                         # 100
t.location.latitude              # 12.345
```

If the parent and child are updated in one go, PaperTrail can use the
aforementioned `transaction_id` to reify the models as they were before the
transaction (instead of before the update to the model).

```ruby
treasure.amount                  # 100
treasure.location.latitude       # 12.345

Treasure.transaction do
treasure.location.update_attributes latitude: 54.321
treasure.update_attributes amount: 153
end

t = treasure.versions.last.reify(has_one: true)
t.amount                         # 100
t.location.latitude              # 12.345, instead of 54.321
```

By default, PaperTrail excludes an associated record from the reified parent
model if the associated record exists in the live model but did not exist as at
the time the version was created. This is usually what you want if you just want
to look at the reified version. But if you want to persist it, it would be
better to pass in option `mark_for_destruction: true` so that the associated
record is included and marked for destruction. Note that `mark_for_destruction`
only has [an effect on associations marked with `autosave: true`][32].

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit, autosave: true
end

class Wotsit < ActiveRecord::Base
  has_paper_trail
  belongs_to :widget
end

widget = Widget.create(name: 'widget_0')
widget.update_attributes(name: 'widget_1')
widget.create_wotsit(name: 'wotsit')

widget_0 = widget.versions.last.reify(has_one: true)
widget_0.wotsit                                  # nil

widget_0 = widget.versions.last.reify(has_one: true, mark_for_destruction: true)
widget_0.wotsit.marked_for_destruction?          # true
widget_0.save!
widget.reload.wotsit                             # nil
```

#### 4.b.1. Known Issues

Associations are an **experimental feature** and have the following known
issues, in order of descending importance.

1. PaperTrail only reifies the first level of associations.
1. [#542](https://github.com/airblade/paper_trail/issues/542) -
   Not compatible with [transactional tests][34], aka. transactional fixtures.
1. Requires database timestamp columns with fractional second precision.
   - Sqlite and postgres timestamps have fractional second precision by default.
   [MySQL timestamps do not][35]. Furthermore, MySQL 5.5 and earlier do not
   support fractional second precision at all.
   - Also, support for fractional seconds in MySQL was not added to
   rails until ActiveRecord 4.2 (https://github.com/rails/rails/pull/14359).
1. PaperTrail can't restore an association properly if the association record
   can be updated to replace its parent model (by replacing the foreign key)
1. Currently PaperTrail only supports a single `version_associations` table.
   Therefore, you can only use a single table to store the versions for
   all related models. Sorry for those who use multiple version tables.
1. PaperTrail relies on the callbacks on the association model (and the :through
   association model for Has-Many-Through associations) to record the versions
   and the relationship between the versions. If the association is changed
   without invoking the callbacks, Reification won't work. Below are some
   examples:

Given these models:

```ruby
class Book < ActiveRecord::Base
  has_many :authorships, dependent: :destroy
  has_many :authors, through: :authorships, source: :person
  has_paper_trail
end

class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :person
  has_paper_trail      # NOTE
end

class Person < ActiveRecord::Base
  has_many :authorships, dependent: :destroy
  has_many :books, through: :authorships
  has_paper_trail
end
```

Then each of the following will store authorship versions:

```ruby
@book.authors << @dostoyevsky
@book.authors.create name: 'Tolstoy'
@book.authorships.last.destroy
@book.authorships.clear
@book.author_ids = [@solzhenistyn.id, @dostoyevsky.id]
```

But none of these will:

```ruby
@book.authors.delete @tolstoy
@book.author_ids = []
@book.authors = []
```

Having said that, you can apparently get all these working (I haven't tested it
myself) with this patch:

```ruby
# In config/initializers/active_record_patch.rb
module ActiveRecord
  # = Active Record Has Many Through Association
  module Associations
    class HasManyThroughAssociation < HasManyAssociation #:nodoc:
      alias_method :original_delete_records, :delete_records

      def delete_records(records, method)
        method ||= :destroy
        original_delete_records(records, method)
      end
    end
  end
end
```

See [issue 113][16] for a discussion about this.

### 4.c. Storing Metadata

You can store arbitrary model-level metadata alongside each version like this:

```ruby
class Article < ActiveRecord::Base
  belongs_to :author
  has_paper_trail meta: { author_id:  :author_id,
                          word_count: :count_words,
                          answer:     42 }
  def count_words
    153
  end
end
```

PaperTrail will call your proc with the current article and store the result in
the `author_id` column of the `versions` table.
Don't forget to add any such columns to your `versions` table.

#### Advantages of Metadata

Why would you do this?  In this example, `author_id` is an attribute of
`Article` and PaperTrail will store it anyway in a serialized form in the
`object` column of the `version` record.  But let's say you wanted to pull out
all versions for a particular author; without the metadata you would have to
deserialize (reify) each `version` object to see if belonged to the author in
question.  Clearly this is inefficient.  Using the metadata you can find just
those versions you want:

```ruby
PaperTrail::Version.where(author_id: author_id)
```

#### Metadata from Controllers

You can also store any information you like from your controller.  Override
the `info_for_paper_trail` method in your controller to return a hash whose keys
correspond to columns in your `versions` table.

```ruby
class ApplicationController
  def info_for_paper_trail
    { ip: request.remote_ip, user_agent: request.user_agent }
  end
end
```

## 5. ActiveRecord

### 5.a. Single Table Inheritance (STI)

PaperTrail supports [Single Table Inheritance][39], and even supports an
un-versioned base model, as of `23ffbdc7e1`.

```ruby
class Fruit < ActiveRecord::Base
  # un-versioned base model
end
class Banana < Fruit
  has_paper_trail
end
```

However, there is a known issue when reifying [associations](#associations),
see https://github.com/airblade/paper_trail/issues/594

### 5.b. Configuring the `versions` Association

You may configure the name of the `versions` association by passing
a different name to `has_paper_trail`.

```ruby
class Post < ActiveRecord::Base
  has_paper_trail class_name: 'Version', versions: :drafts
end

Post.new.versions # => NoMethodError
```

Overriding (instead of configuring) the `versions` method is not supported.
Overriding associations is not recommended in general.

### 5.c. Generators

PaperTrail has one generator, `paper_trail:install`. It writes, but does not
run, a migration file.  It also creates a PaperTrail configuration initializer.
The migration adds (at least) the `versions` table. The
most up-to-date documentation for this generator can be found by running `rails
generate paper_trail:install --help`, but a copy is included here for
convenience.

```
Usage:
  rails generate paper_trail:install [options]

Options:
  [--with-changes], [--no-with-changes]            # Store changeset (diff) with each version
  [--with-associations], [--no-with-associations]  # Store transactional IDs to support association restoration

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist

Generates (but does not run) a migration to add a versions table.  Also generates an initializer file for configuring PaperTrail
```

### 5.d. Protected Attributes

As of version 6, PT no longer supports rails 3 or the [protected_attributes][17]
gem. If you are still using them, you may use PT 5 or lower. We recommend
upgrading to [strong_parameters][18] as soon as possible.  

If you must use [protected_attributes][17] for now, and want to use PT > 5, you 
can reopen `PaperTrail::Version` and add the following `attr_accessible` fields:

```ruby
# app/models/paper_trail/version.rb
module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
    attr_accessible :item_type, :item_id, :event, :whodunnit, :object, :object_changes, :created_at
  end
end
```

This unsupported workaround has been tested with protected_attributes 1.0.9 /
rails 4.2.8 / paper_trail 7.0.3.

## 6. Extensibility

### 6.a. Custom Version Classes

You can specify custom version subclasses with the `:class_name` option:

```ruby
class PostVersion < PaperTrail::Version
  # custom behaviour, e.g:
  self.table_name = :post_versions
end

class Post < ActiveRecord::Base
  has_paper_trail class_name: 'PostVersion'
end
```

Unlike ActiveRecord's `class_name`, you'll have to supply the complete module
path to the class (e.g. `Foo::BarVersion` if your class is inside the module
`Foo`).

#### Advantages

1. For models which have a lot of versions, storing each model's versions in a
   separate table can improve the performance of certain database queries.
1. Store different version [metadata](#storing-metadata) for different models.

#### Configuration

If you are using Postgres, you should also define the sequence that your custom
version class will use:

```ruby
class PostVersion < PaperTrail::Version
  self.table_name = :post_versions
  self.sequence_name = :post_versions_id_seq
end
```

If you only use custom version classes and don't have a `versions` table, you
must let ActiveRecord know that the `PaperTrail::Version` class is an
`abstract_class`.

```ruby
# app/models/paper_trail/version.rb
module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
    self.abstract_class = true
  end
end
```

You can also specify custom names for the versions and version associations.
This is useful if you already have `versions` or/and `version` methods on your
model.  For example:

```ruby
class Post < ActiveRecord::Base
  has_paper_trail versions: :paper_trail_versions,
                  version:  :paper_trail_version

  # Existing versions method.  We don't want to clash.
  def versions
    # ...
  end

  # Existing version method.  We don't want to clash.
  def version
    # ...
  end
end
```

### 6.b. Custom Serializer

By default, PaperTrail stores your changes as a `YAML` dump. You can override
this with the serializer config option:

```ruby
PaperTrail.serializer = MyCustomSerializer
```

A valid serializer is a `module` (or `class`) that defines a `load` and `dump`
method.  These serializers are included in the gem for your convenience:

* [PaperTrail::Serializers::YAML][24] - Default
* [PaperTrail::Serializers::JSON][25]

#### PostgreSQL JSON column type support

If you use PostgreSQL, and would like to store your `object` (and/or
`object_changes`) data in a column of [type `json` or type `jsonb`][26], specify
`json` instead of `text` for these columns in your migration:

```ruby
create_table :versions do |t|
  # ...
  t.json :object          # Full object changes
  t.json :object_changes  # Optional column-level changes
  # ...
end
```

If you use the PostgreSQL `json` or `jsonb` column type, you do not need
to specify a `PaperTrail.serializer`.

##### Convert existing YAML data to JSON

If you've been using PaperTrail for a while with the default YAML serializer
and you want to switch to JSON or JSONB, you're in a bit of a bind because
there's no automatic way to migrate your data. The first (slow) option is to
loop over every record and parse it in Ruby, then write to a temporary column:

```ruby
add_column :versions, :new_object, :jsonb # or :json

PaperTrail::Version.reset_column_information
PaperTrail::Version.find_each do |version|
  version.update_column :new_object, YAML.load(version.object)
end

remove_column :versions, :object
rename_column :versions, :new_object, :object
```

This technique can be very slow if you have a lot of data. Though slow, it is
safe in databases where transactions are protected against DDL, such as
Postgres. In databases without such protection, such as MySQL, a table lock may
be necessary.

If the above technique is too slow for your needs, and you're okay doing without
PaperTrail data temporarily, you can create the new column without converting
the data.

```ruby
rename_column :versions, :object, :old_object
add_column :versions, :object, :jsonb # or :json
```

After that migration, your historical data still exists as YAML, and new data
will be stored as JSON. Next, convert records from YAML to JSON using a
background script.

```ruby
PaperTrail::Version.where.not(old_object: nil).find_each do |version|
  version.update_columns old_object: nil, object: YAML.load(version.old_object)
end
```

Finally, in another migration, remove the old column.

```ruby
remove_column :versions, :old_object
```

If you use the optional `object_changes` column, don't forget to convert it
also, using the same technique.

##### Convert a Column from Text to JSON

If your `object` column already contains JSON data, and you want to change its
data type to `json` or `jsonb`, you can use the following [DDL][36]. Of course,
if your `object` column contains YAML, you must first convert the data to JSON
(see above) before you can change the column type.

Using SQL:

```sql
alter table versions
alter column object type jsonb
using object::jsonb;
```

Using ActiveRecord:

```ruby
class ConvertVersionsObjectToJson < ActiveRecord::Migration
  def up
    change_column :versions, :object, 'jsonb USING object::jsonb'
  end

  def down
    change_column :versions, :object, 'text USING object::text'
  end
end
```

## 7. Testing

You may want to turn PaperTrail off to speed up your tests.  See [Turning
PaperTrail Off](#2d-turning-papertrail-off) above.

### 7.a. Minitest

First, disable PT for the entire `ruby` process.

```ruby
# in config/environments/test.rb
config.after_initialize do
  PaperTrail.enabled = false
end
```

Then, to enable PT for specific tests, you can add a `with_versioning` test
helper method.

```ruby
# in test/test_helper.rb
def with_versioning
  was_enabled = PaperTrail.enabled?
  was_enabled_for_controller = PaperTrail.enabled_for_controller?
  PaperTrail.enabled = true
  PaperTrail.enabled_for_controller = true
  begin
    yield
  ensure
    PaperTrail.enabled = was_enabled
    PaperTrail.enabled_for_controller = was_enabled_for_controller
  end
end
```

Then, use the helper in your tests.

```ruby
test 'something that needs versioning' do
  with_versioning do
    # your test
  end
end
```

### 7.b. RSpec

PaperTrail provides a helper, `paper_trail/frameworks/rspec.rb`, that works with
[RSpec][27] to make it easier to control when `PaperTrail` is enabled during
testing.

```ruby
# spec/rails_helper.rb
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
# ...
require 'paper_trail/frameworks/rspec'
```

With the helper loaded, PaperTrail will be turned off for all tests by
default. To enable PaperTrail for a test you can either wrap the
test in a `with_versioning` block, or pass in `versioning: true` option to a
spec block.

```ruby
describe 'RSpec test group' do
  it 'by default, PaperTrail will be turned off' do
    expect(PaperTrail).to_not be_enabled
  end

  with_versioning do
    it 'within a `with_versioning` block it will be turned on' do
      expect(PaperTrail).to be_enabled
    end
  end

  it 'can be turned on at the `it` or `describe` level', versioning: true do
    expect(PaperTrail).to be_enabled
  end
end
```

The helper will also reset the `PaperTrail.whodunnit` value to `nil` before each
test to help prevent data spillover between tests. If you are using PaperTrail
with Rails, the helper will automatically set the `PaperTrail.controller_info`
value to `{}` as well, again, to help prevent data spillover between tests.

There is also a `be_versioned` matcher provided by PaperTrail's RSpec helper
which can be leveraged like so:

```ruby
class Widget < ActiveRecord::Base
end

describe Widget do
  it 'is not versioned by default' do
    is_expected.to_not be_versioned
  end

  describe 'add versioning to the `Widget` class' do
    before(:all) do
      class Widget < ActiveRecord::Base
        has_paper_trail
      end
    end

    it 'enables paper trail' do
      is_expected.to be_versioned
    end
  end
end
```

#### Matchers

The `have_a_version_with` matcher makes assertions about versions using
`where_object`, based on the `object` column.

```ruby
describe '`have_a_version_with` matcher' do
  it 'is possible to do assertions on version attributes' do
    widget.update_attributes!(name: 'Leonard', an_integer: 1)
    widget.update_attributes!(name: 'Tom')
    widget.update_attributes!(name: 'Bob')
    expect(widget).to have_a_version_with name: 'Leonard', an_integer: 1
    expect(widget).to have_a_version_with an_integer: 1
    expect(widget).to have_a_version_with name: 'Tom'
  end
end
```

The `have_a_version_with_changes` matcher makes assertions about versions using
`where_object_changes`, based on the optional
[`object_changes` column](#3c-diffing-versions).

```ruby
describe '`have_a_version_with_changes` matcher' do
  it 'is possible to do assertions on version changes' do
    widget.update_attributes!(name: 'Leonard', an_integer: 1)
    widget.update_attributes!(name: 'Tom')
    widget.update_attributes!(name: 'Bob')
    expect(widget).to have_a_version_with_changes name: 'Leonard', an_integer: 2
    expect(widget).to have_a_version_with_changes an_integer: 2
    expect(widget).to have_a_version_with_changes name: 'Bob'
  end
end
```

For more examples of the RSpec matchers, see the
[Widget spec](https://github.com/airblade/paper_trail/blob/master/spec/models/widget_spec.rb)

### 7.c. Cucumber

PaperTrail provides a helper for [Cucumber][28] that works similar to the RSpec
helper. If you want to use the helper, you will need to require in your cucumber
helper like so:

```ruby
# features/support/env.rb

ENV["RAILS_ENV"] ||= 'cucumber'
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
# ...
require 'paper_trail/frameworks/cucumber'
```

When the helper is loaded, PaperTrail will be turned off for all scenarios by a
`before` hook added by the helper by default. When you want to enable PaperTrail
for a scenario, you can wrap code in a `with_versioning` block in a step, like
so:

```ruby
Given /I want versioning on my model/ do
  with_versioning do
    # PaperTrail will be turned on for all code inside of this block
  end
end
```

The helper will also reset the `PaperTrail.whodunnit` value to `nil` before each
test to help prevent data spillover between tests. If you are using PaperTrail
with Rails, the helper will automatically set the `PaperTrail.controller_info`
value to `{}` as well, again, to help prevent data spillover between tests.

### 7.d. Spork

If you want to use the `RSpec` or `Cucumber` helpers with [Spork][29], you will
need to manually require the helper(s) in your `prefork` block on your test
helper, like so:

```ruby
# spec/rails_helper.rb

require 'spork'

Spork.prefork do
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require 'spec_helper'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'paper_trail/frameworks/rspec'
  require 'paper_trail/frameworks/cucumber'
  # ...
end
```

### 7.e. Zeus or Spring

If you want to use the `RSpec` or `Cucumber` helpers with [Zeus][30] or
[Spring][31], you will need to manually require the helper(s) in your test
helper, like so:

```ruby
# spec/rails_helper.rb

ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'paper_trail/frameworks/rspec'
```

## 8. Integration with Other Libraries

- [ActiveAdmin][42]
- Sinatra - [paper_trail-sinatra][41]

## Articles

* [Jutsu #8 - Version your RoR models with PaperTrail](http://samurails.com/gems/papertrail/),
  [Thibault](http://samurails.com/about-me/), 29th September 2014
* [Versioning with PaperTrail](http://www.sitepoint.com/versioning-papertrail),
  [Ilya Bodrov](http://www.sitepoint.com/author/ibodrov), 10th April 2014
* [Using PaperTrail to track stack traces](http://web.archive.org/web/20141120233916/http://rubyrailsexpert.com/?p=36),
  T James Corcoran's blog, 1st October 2013.
* [RailsCast #255 - Undo with PaperTrail](http://railscasts.com/episodes/255-undo-with-paper-trail),
  28th February 2011.
* [Keep a Paper Trail with PaperTrail](http://www.linux-mag.com/id/7528),
  Linux Magazine, 16th September 2009.

## Problems

Please use GitHub's [issue tracker](http://github.com/airblade/paper_trail/issues).

## Contributors

Created by Andy Stewart in 2010, maintained since 2012 by Ben Atkins, since 2015
by Jared Beck, with contributions by over 150 people.

https://github.com/airblade/paper_trail/graphs/contributors

## Contributing

See our [contribution guidelines][43]

## Inspirations

* [Simply Versioned](http://github.com/github/simply_versioned)
* [Acts As Audited](http://github.com/collectiveidea/acts_as_audited)

## Intellectual Property

Copyright (c) 2011 Andy Stewart (boss@airbladesoftware.com).
Released under the MIT licence.

[1]: http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html
[2]: https://github.com/airblade/paper_trail/issues/163
[3]: http://railscasts.com/episodes/255-undo-with-paper-trail
[4]: https://api.travis-ci.org/airblade/paper_trail.svg?branch=master
[5]: https://travis-ci.org/airblade/paper_trail
[6]: https://img.shields.io/gemnasium/airblade/paper_trail.svg
[7]: https://gemnasium.com/airblade/paper_trail
[9]: https://github.com/airblade/paper_trail/tree/3.0-stable
[10]: https://github.com/airblade/paper_trail/tree/2.7-stable
[11]: https://github.com/airblade/paper_trail/tree/rails2
[14]: https://raw.github.com/airblade/paper_trail/master/lib/generators/paper_trail/templates/create_versions.rb
[16]: https://github.com/airblade/paper_trail/issues/113
[17]: https://github.com/rails/protected_attributes
[18]: https://github.com/rails/strong_parameters
[19]: http://github.com/myobie/htmldiff
[20]: http://github.com/pvande/differ
[21]: https://github.com/halostatue/diff-lcs
[22]: http://github.com/jeremyw/paper_trail/blob/master/lib/paper_trail/has_paper_trail.rb#L151-156
[23]: http://github.com/tim/activerecord-diff
[24]: https://github.com/airblade/paper_trail/blob/master/lib/paper_trail/serializers/yaml.rb
[25]: https://github.com/airblade/paper_trail/blob/master/lib/paper_trail/serializers/json.rb
[26]: http://www.postgresql.org/docs/9.4/static/datatype-json.html
[27]: https://github.com/rspec/rspec
[28]: http://cukes.info
[29]: https://github.com/sporkrb/spork
[30]: https://github.com/burke/zeus
[31]: https://github.com/rails/spring
[32]: http://api.rubyonrails.org/classes/ActiveRecord/AutosaveAssociation.html#method-i-mark_for_destruction
[33]: https://github.com/airblade/paper_trail/wiki/Setting-whodunnit-in-the-rails-console
[34]: https://github.com/rails/rails/blob/591a0bb87fff7583e01156696fbbf929d48d3e54/activerecord/lib/active_record/fixtures.rb#L142
[35]: https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html
[36]: http://www.postgresql.org/docs/9.4/interactive/ddl.html
[37]: https://github.com/ankit1910/paper_trail-globalid
[38]: https://github.com/sferik/rails_admin
[39]: http://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance
[40]: http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#module-ActiveRecord::Associations::ClassMethods-label-Polymorphic+Associations
[41]: https://github.com/jaredbeck/paper_trail-sinatra
[42]: https://github.com/activeadmin/activeadmin/wiki/Auditing-via-paper_trail-%28change-history%29
[43]: https://github.com/airblade/paper_trail/blob/master/.github/CONTRIBUTING.md
