# PaperTrail

[![Build Status][4]][5] [![Dependency Status][6]][7]

Track changes to your models, for auditing or versioning. See how a model looked
at any stage in its lifecycle, revert it to any version, or restore it after it
has been destroyed.

- [Features](#features)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [API Summary](#api-summary)
- [Basic Usage](#basic-usage)
- Limiting What is Versioned, and When
  - [Choosing Lifecycle Events To Monitor](#choosing-lifecycle-events-to-monitor)
  - [Choosing When To Save New Versions](#choosing-when-to-save-new-versions)
  - [Choosing Attributes To Monitor](#choosing-attributes-to-monitor)
  - [Turning PaperTrail Off/On](#turning-papertrail-offon)
  - [Limiting the Number of Versions Created](#limiting-the-number-of-versions-created)
- Working With Versions
  - [Reverting And Undeleting A Model](#reverting-and-undeleting-a-model)
  - [Navigating Versions](#navigating-versions)
  - [Diffing Versions](#diffing-versions)
  - [Deleting Old Versions](#deleting-old-versions)
- [Finding Out Who Was Responsible For A Change](#finding-out-who-was-responsible-for-a-change)
- [Custom Version Classes](#custom-version-classes)
- [Associations](#associations)
- [Storing metadata](#storing-metadata)
- [Using a custom serializer](#using-a-custom-serializer)
- [SerializedAttributes support](#serializedattributes-support)
- [Testing](#testing)

## Features

* Stores create, update and destroy events
  * Does not store updates which don't change anything
  * Support for versioning associated records
* Can store metadata with each version record
  * Who was responsible for a change
  * Arbitrary model-level metadata (useful for filtering versions)
  * Arbitrary controller-level information e.g. remote IP
* Configurable
  * No configuration necessary, but if you want to ..
  * Configure which events (create, update and destroy) are versioned
  * Configure which attributes must change for an update to be versioned
  * Turn off/on by model, request, or globally
  * Use separate tables for separate models
* Extensible
  * Write a custom version class for complete control
  * Write custom version classes for each of your models
* Work with versions
  * Restore any version, including the original, even once destroyed
  * Restore any version even if the schema has since changed
  * Restore the version as of a particular time
* Thoroughly tested
* Threadsafe

## Compatibility

| paper_trail | branch     | tags   | ruby     | activerecord |
| ----------- | ---------- | ------ | -------- | ------------ |
| 4           | master     | v4.x   | >= 1.8.7 | >= 3.0, < 6  |
| 3           | 3.0-stable | v3.x   | >= 1.8.7 | >= 3.0, < 5  |
| 2           | 2.7-stable | v2.x   | >= 1.8.7 | >= 3.0, < 4  |
| 1           | rails2     | v1.x   | >= 1.8.7 | >= 2.3, < 3  |

## Installation

### Rails 3 and 4

1. Add PaperTrail to your `Gemfile`.

    `gem 'paper_trail', '~> 4.0.2'`

2. Generate a migration which will add a `versions` table to your database.

    `bundle exec rails generate paper_trail:install`

3. Run the migration.

    `bundle exec rake db:migrate`

4. Add `has_paper_trail` to the models you want to track.

### Sinatra

In order to configure PaperTrail for usage with [Sinatra][12], your `Sinatra`
app must be using `ActiveRecord` 3 or 4. It is also recommended to use the
[Sinatra ActiveRecord Extension][13] or something similar for managing your
applications `ActiveRecord` connection in a manner similar to the way `Rails`
does. If using the aforementioned `Sinatra ActiveRecord Extension`, steps for
setting up your app with PaperTrail will look something like this:

1. Add PaperTrail to your `Gemfile`.

    `gem 'paper_trail', '~> 4.0.2'`

2. Generate a migration to add a `versions` table to your database.

    `bundle exec rake db:create_migration NAME=create_versions`

3. Copy contents of [create_versions.rb][14]
into the `create_versions` migration that was generated into your `db/migrate` directory.

4. Run the migration.

    `bundle exec rake db:migrate`

5. Add `has_paper_trail` to the models you want to track.


PaperTrail provides a helper extension that acts similar to the controller mixin
it provides for `Rails` applications.

It will set `PaperTrail.whodunnit` to whatever is returned by a method named
`user_for_paper_trail` which you can define inside your Sinatra Application. (by
default it attempts to invoke a method named `current_user`)

If you're using the modular [`Sinatra::Base`][15] style of application, you will
need to register the extension:

```ruby
# bleh_app.rb
require 'sinatra/base'

class BlehApp < Sinatra::Base
  register PaperTrail::Sinatra
end
```

## API Summary

When you declare `has_paper_trail` in your model, you get these methods:

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail   # you can pass various options here
end

# Returns this widget's versions.  You can customise the name of the association.
widget.versions

# Return the version this widget was reified from, or nil if it is live.
# You can customise the name of the method.
widget.version

# Returns true if this widget is the current, live one; or false if it is from a previous version.
widget.live?

# Returns who put the widget into its current state.
widget.paper_trail_originator

# Returns the widget (not a version) as it looked at the given timestamp.
widget.version_at(timestamp)

# Returns the widget (not a version) as it was most recently.
widget.previous_version

# Returns the widget (not a version) as it became next.
widget.next_version

# Generates a version for a `touch` event (`widget.touch` does NOT generate a version)
widget.touch_with_version

# Turn PaperTrail off for all widgets.
Widget.paper_trail_off!

# Turn PaperTrail on for all widgets.
Widget.paper_trail_on!

# Check whether PaperTrail is enabled for all widgets.
Widget.paper_trail_enabled_for_model?
widget.paper_trail_enabled_for_model? # only available on instances of versioned models
```

And a `PaperTrail::Version` instance has these methods:

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

# Query versions objects by attributes.
PaperTrail::Version.where_object(attr1: val1, attr2: val2)

# Query versions object_changes field by attributes (requires
# `object_changes` column on versions table).
# Also can't guarantee consistent query results for numeric values
# due to limitations of SQL wildcard matchers against the serialized objects.
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

## Basic Usage

PaperTrail is simple to use.  Just add 15 characters to a model to get a paper
trail of every `create`, `update`, and `destroy`.

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail
end
```

This gives you a `versions` method which returns the paper trail of changes to
your model.

```ruby
widget = Widget.find 42
widget.versions
# [<PaperTrail::Version>, <PaperTrail::Version>, ...]
```

Once you have a version, you can find out what happened:

```ruby
v = widget.versions.last
v.event                     # 'update' (or 'create' or 'destroy')
v.whodunnit                 # '153'  (if the update was via a controller and
                            #         the controller has a current_user method,
                            #         here returning the id of the current user)
v.created_at                # when the update occurred
widget = v.reify            # the widget as it was before the update;
                            # would be nil for a create event
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
widget.update_attributes :name => 'Wotsit'
widget.versions.last.reify.name             # 'Doobly'
widget.versions.last.event                  # 'update'
```

This also means that PaperTrail does not waste space storing a version of the
object as it currently stands.  The `versions` method gives you previous
versions; to get the current one just call a finder on your `Widget` model as
usual.

Here's a helpful table showing what PaperTrail stores:

<table>
  <tr>
    <th>Event</th>
    <th>Model Before</th>
    <th>Model After</th>
  </tr>
  <tr>
    <td>create</td>
    <td>nil</td>
    <td>widget</td>
  </tr>
  <tr>
    <td>update</td>
    <td>widget</td>
    <td>widget</td>
  <tr>
    <td>destroy</td>
    <td>widget</td>
    <td>nil</td>
  </tr>
</table>

PaperTrail stores the values in the Model Before column.  Most other
auditing/versioning plugins store the After column.


## Choosing Lifecycle Events To Monitor

You can choose which events to track with the `on` option.  For example, to
ignore `create` events:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :on => [:update, :destroy]
end
```

You may also have the `PaperTrail::Version` model save a custom string in it's
`event` field instead of the typical `create`, `update`, `destroy`. PaperTrail
supplies a custom accessor method called `paper_trail_event`, which it will
attempt to use to fill the `event` field before falling back on one of the
default events.

```ruby
a = Article.create
a.versions.size                           # 1
a.versions.last.event                     # 'create'
a.paper_trail_event = 'update title'
a.update_attributes :title => 'My Title'
a.versions.size                           # 2
a.versions.last.event                     # 'update title'
a.paper_trail_event = nil
a.update_attributes :title => "Alternate"
a.versions.size                           # 3
a.versions.last.event                     # 'update'
```

## Choosing When To Save New Versions

You can choose the conditions when to add new versions with the `if` and
`unless` options. For example, to save versions only for US non-draft
translations:

```ruby
class Translation < ActiveRecord::Base
  has_paper_trail :if     => Proc.new { |t| t.language_code == 'US' },
                  :unless => Proc.new { |t| t.type == 'DRAFT'       }
end
```


## Choosing Attributes To Monitor

You can ignore changes to certain attributes like this:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :ignore => [:title, :rating]
end
```

This means that changes to just the `title` or `rating` will not store another
version of the article.  It does not mean that the `title` and `rating`
attributes will be ignored if some other change causes a new
`PaperTrail::Version` to be created.  For example:

```ruby
a = Article.create
a.versions.length                         # 1
a.update_attributes :title => 'My Title', :rating => 3
a.versions.length                         # 1
a.update_attributes :title => 'Greeting', :content => 'Hello'
a.versions.length                         # 2
a.previous_version.title                  # 'My Title'
```

Or, you can specify a list of all attributes you care about:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :only => [:title]
end
```

This means that only changes to the `title` will save a version of the article:

```ruby
a = Article.create
a.versions.length                         # 1
a.update_attributes :title => 'My Title'
a.versions.length                         # 2
a.update_attributes :content => 'Hello'
a.versions.length                         # 2
a.previous_version.content                # nil
```

The `:ignore` and `:only` options can also accept `Hash` arguments, where the :

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :only => [:title => Proc.new { |obj| !obj.title.blank? } ]
end
```

This means that if the `title` is not blank, then only changes to the `title`
will save a version of the article:

```ruby
a = Article.create
a.versions.length                         # 1
a.update_attributes :content => 'Hello'
a.versions.length                         # 2
a.update_attributes :title => 'My Title'
a.versions.length                         # 3
a.update_attributes :content => 'Hai'
a.versions.length                         # 3
a.previous_version.content                # "Hello"
a.update_attributes :title => 'Dif Title'
a.versions.length                         # 4
a.previous_version.content                # "Hai"
```

Passing both `:ignore` and `:only` options will result in the article being
saved if a changed attribute is included in `:only` but not in `:ignore`.

You can skip fields altogether with the `:skip` option.  As with `:ignore`,
updates to these fields will not create a new `PaperTrail::Version`.  In
addition, these fields will not be included in the serialized version of the
object whenever a new `PaperTrail::Version` is created.

For example:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :skip => [:file_upload]
end
```

## Turning PaperTrail Off/On

Sometimes you don't want to store changes.  Perhaps you are only interested in
changes made by your users and don't need to store changes you make yourself in,
say, a migration -- or when testing your application.

You can turn PaperTrail on or off in three ways: globally, per request, or per
class.

### Globally

On a global level you can turn PaperTrail off like this:

```ruby
PaperTrail.enabled = false
```

For example, you might want to disable PaperTrail in your Rails application's
test environment to speed up your tests.  This will do it (note: this gets done
automatically for `RSpec` and `Cucumber`, please see the [Testing
section](#testing)):

```ruby
# in config/environments/test.rb
config.after_initialize do
  PaperTrail.enabled = false
end
```

If you disable PaperTrail in your test environment but want to enable it for
specific tests, you can add a helper like this to your test helper:

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

And then use it in your tests like this:

```ruby
test "something that needs versioning" do
  with_versioning do
    # your test
  end
end
```

### Per request

You can turn PaperTrail on or off per request by adding a
`paper_trail_enabled_for_controller` method to your controller which returns
`true` or `false`:

```ruby
class ApplicationController < ActionController::Base
  def paper_trail_enabled_for_controller
    request.user_agent != 'Disable User-Agent'
  end
end
```

### Per class

If you are about to change some widgets and you don't want a paper trail of your
changes, you can turn PaperTrail off like this:

```ruby
Widget.paper_trail_off!
```

And on again like this:

```ruby
Widget.paper_trail_on!
```

### Per method call

You can call a method without creating a new version using `without_versioning`.
 It takes either a method name as a symbol:

```ruby
@widget.without_versioning :destroy
```

Or a block:

```ruby
@widget.without_versioning do
  @widget.update_attributes :name => 'Ford'
end
```

## Limiting the Number of Versions Created

Configure `version_limit` to cap the number of versions saved per record. This
does not apply to `create` events.

```ruby
# Limit: 4 versions per record (3 most recent, plus a `create` event)
PaperTrail.config.version_limit = 3
# Remove the limit
PaperTrail.config.version_limit = nil
```

## Reverting And Undeleting A Model

PaperTrail makes reverting to a previous version easy:

```ruby
widget = Widget.find 42
widget.update_attributes :name => 'Blah blah'
# Time passes....
widget = widget.previous_version  # the widget as it was before the update
widget.save                       # reverted
```

Alternatively you can find the version at a given time:

```ruby
widget = widget.version_at(1.day.ago)  # the widget as it was one day ago
widget.save                            # reverted
```

Note `version_at` gives you the object, not a version, so you don't need to call
`reify`.

Undeleting is just as simple:

```ruby
widget = Widget.find 42
widget.destroy
# Time passes....
widget = PaperTrail::Version.find(153).reify  # the widget as it was before destruction
widget.save                         # the widget lives!
```

You could even use PaperTrail to implement an undo system, [Ryan Bates has!][3]

If your model uses [optimistic locking][1] don't forget to [increment your
`lock_version`][2] before saving or you'll get a `StaleObjectError`.

## Navigating Versions

You can call `previous_version` and `next_version` on an item to get it as it
was/became.  Note that these methods reify the item for you.

```ruby
live_widget = Widget.find 42
live_widget.versions.length           # 4 for example
widget = live_widget.previous_version # => widget == live_widget.versions.last.reify
widget = widget.previous_version      # => widget == live_widget.versions[-2].reify
widget = widget.next_version          # => widget == live_widget.versions.last.reify
widget.next_version                   # live_widget
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
widget = widget.previous_version
widget.live?                        # false
```

And you can perform `WHERE` queries for object versions based on attributes:

```ruby
# All versions that meet these criteria.
PaperTrail::Version.where_object(content: "Hello", title: "Article")
```

## Diffing Versions

There are two scenarios: diffing adjacent versions and diffing non-adjacent
versions.

The best way to diff adjacent versions is to get PaperTrail to do it for you.
If you add an `object_changes` text column to your `versions` table, either at
installation time with the `rails generate paper_trail:install --with-changes`
option or manually, PaperTrail will store the `changes` diff (excluding any
attributes PaperTrail is ignoring) in each `update` version.  You can use the
`version.changeset` method to retrieve it.  For example:

```ruby
widget = Widget.create :name => 'Bob'
widget.versions.last.changeset
# {
#   "name"=>[nil, "Bob"],
#   "created_at"=>[nil, 2015-08-10 04:10:40 UTC],
#   "updated_at"=>[nil, 2015-08-10 04:10:40 UTC],
#   "id"=>[nil, 1]
# }
widget.update_attributes :name => 'Robert'
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

If you wish to selectively record changes for some models but not others you
can opt out of recording changes by passing `:save_changes => false` to your
`has_paper_trail` method declaration.

## Deleting Old Versions

Over time your `versions` table will grow to an unwieldy size.  Because each
version is self-contained (see the Diffing section above for more) you can
simply delete any records you don't want any more.  For example:

```sql
sql> delete from versions where created_at < 2010-06-01;
```

```ruby
PaperTrail::Version.delete_all ["created_at < ?", 1.week.ago]
```

## Finding Out Who Was Responsible For A Change

If your `ApplicationController` has a `current_user` method, PaperTrail will
attempt to store the value returned by `current_user.id` in the version's
`whodunnit` column.

You may want PaperTrail to call a different method to find out who is
responsible.  To do so, override the `user_for_paper_trail` method in your
controller like this:

```ruby
class ApplicationController
  def user_for_paper_trail
    logged_in? ? current_member.id : 'Public user'  # or whatever
  end
end
```

In a console session you can manually set who is responsible like this:

```ruby
PaperTrail.whodunnit = 'Andy Stewart'
widget.update_attributes :name => 'Wibble'
widget.versions.last.whodunnit              # Andy Stewart
```

See also: [Setting whodunnit in the rails console][33]

Sometimes you want to define who is responsible for a change in a small scope
without overwriting value of `PaperTrail.whodunnit`. It is possible to define
the `whodunnit` value for an operation inside a block like this:

```ruby
PaperTrail.whodunnit = 'Andy Stewart'
widget.whodunnit('Lucas Souza') do
  widget.update_attributes :name => 'Wibble'
end
widget.versions.last.whodunnit              # Lucas Souza
widget.update_attributes :name => 'Clair'
widget.versions.last.whodunnit              # Andy Stewart
widget.whodunnit('Ben Atkins') { |w| w.update_attributes :name => 'Beth' } # this syntax also works
widget.versions.last.whodunnit              # Ben Atkins
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
widget.update_attributes :name => 'Yankee'
widget..paper_trail_originator              # 'Alice'
PaperTrail.whodunnit = 'Bob'
widget.update_attributes :name => 'Zulu'
widget.paper_trail_originator               # 'Bob'
first_version, last_version = widget.versions.first, widget.versions.last
first_version.whodunnit                     # 'Alice'
first_version.paper_trail_originator        # nil
first_version.terminator                    # 'Alice'
last_version.whodunnit                      # 'Bob'
last_version.paper_trail_originator         # 'Alice'
last_version.terminator                     # 'Bob'
```

## Custom Version Classes

You can specify custom version subclasses with the `:class_name` option:

```ruby
class PostVersion < PaperTrail::Version
  # custom behaviour, e.g:
  self.table_name = :post_versions
end

class Post < ActiveRecord::Base
  has_paper_trail :class_name => 'PostVersion'
end
```

Unlike ActiveRecord's `class_name`, you'll have to supply the complete module path to the class (e.g. `Foo::BarVersion` if your class is inside the module `Foo`).

### Advantages

1. For models which have a lot of versions, storing each model's versions in a
   separate table can improve the performance of certain database queries.
1. Store different version [metadata](#storing-metadata) for different models.

### Configuration

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
  has_paper_trail :versions => :paper_trail_versions,
                  :version  => :paper_trail_version

  # Existing versions method.  We don't want to clash.
  def versions
    ...
  end
  # Existing version method.  We don't want to clash.
  def version
    ...
  end
end
```

## Associations

**Experimental Feature: Known Issues:**
[#542](https://github.com/airblade/paper_trail/issues/542),
[#590](https://github.com/airblade/paper_trail/issues/590).
See also: Caveats below.

PaperTrail can restore three types of associations: Has-One, Has-Many, and
Has-Many-Through. In order to do this, you will need to create a
`version_associations` table, either at installation time with the `rails
generate paper_trail:install --with-associations` option or manually. PaperTrail
will store in that table additional information to correlate versions of the
association and versions of the model when the associated record is changed.
When reifying the model, PaperTrail can use this table, together with the
`transaction_id` to find the correct version of the association and reify it.
The `transaction_id` is a unique id for version records created in the same
transaction. It is used to associate the version of the model and the version of
the association that are created in the same transaction.

To restore Has-One associations as they were at the time, pass option `:has_one
=> true` to `reify`. To restore Has-Many and Has-Many-Through associations, use
option `:has_many => true`.  For example:

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

treasure.update_attributes :amount => 153
treasure.location.update_attributes :latitude => 54.321

t = treasure.versions.last.reify(:has_one => true)
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
treasure.location.update_attributes :latitude => 54.321
treasure.update_attributes :amount => 153
end

t = treasure.versions.last.reify(:has_one => true)
t.amount                         # 100
t.location.latitude              # 12.345, instead of 54.321
```

By default, PaperTrail excludes an associated record from the reified parent
model if the associated record exists in the live model but did not exist as at
the time the version was created. This is usually what you want if you just want
to look at the reified version. But if you want to persist it, it would be
better to pass in option `:mark_for_destruction => true` so that the associated
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

widget = Widget.create(:name => 'widget_0')
widget.update_attributes(:name => 'widget_1')
widget.create_wotsit(:name => 'wotsit')

widget_0 = widget.versions.last.reify(:has_one => true)
widget_0.wotsit                                  # nil

widget_0 = widget.versions.last.reify(:has_one => true, :mark_for_destruction => true)
widget_0.wotsit.marked_for_destruction?          # true
widget_0.save!
widget.reload.wotsit                             # nil
```

**Caveats:**

1. PaperTrail can't restore an association properly if the association record
   can be updated to replace its parent model (by replacing the foreign key)
2. Currently PaperTrail only support single `version_associations` table. The
   implication is that you can only use a single table to store the versions for
   all related models. Sorry for those who use multiple version tables.
3. PaperTrail only reifies the first level of associations, i.e., it does not
   reify any associations of its associations, and so on.
4. PaperTrail relies on the callbacks on the association model (and the :through
   association model for Has-Many-Through associations) to record the versions
   and the relationship between the versions. If the association is changed
   without invoking the callbacks, Reification won't work. Below are some
   examples:

Given these models:

```ruby
class Book < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships, :source => :person
  has_paper_trail
end

class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :person
  has_paper_trail      # NOTE
end

class Person < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :books, :through => :authorships
  has_paper_trail
end
```

Then each of the following will store authorship versions:

```ruby
@book.authors << @dostoyevsky
@book.authors.create :name => 'Tolstoy'
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

## Storing Metadata

You can store arbitrary model-level metadata alongside each version like this:

```ruby
class Article < ActiveRecord::Base
  belongs_to :author
  has_paper_trail :meta => { :author_id  => :author_id,
                             :word_count => :count_words,
                             :answer     => 42 }
  def count_words
    153
  end
end
```

PaperTrail will call your proc with the current article and store the result in
the `author_id` column of the `versions` table.

### Advantages of Metadata

Why would you do this?  In this example, `author_id` is an attribute of
`Article` and PaperTrail will store it anyway in a serialized form in the
`object` column of the `version` record.  But let's say you wanted to pull out
all versions for a particular author; without the metadata you would have to
deserialize (reify) each `version` object to see if belonged to the author in
question.  Clearly this is inefficient.  Using the metadata you can find just
those versions you want:

```ruby
PaperTrail::Version.where(:author_id => author_id)
```

### Metadata from Controllers

You can also store any information you like from your controller.  Override
the `info_for_paper_trail` method in your controller to return a hash whose keys
correspond to columns in your `versions` table.

```ruby
class ApplicationController
  def info_for_paper_trail
    { :ip => request.remote_ip, :user_agent => request.user_agent }
  end
end
```

### Protected Attributes and Metadata

If you are using rails 3 or the [protected_attributes][17] gem you must declare
your metadata columns to be `attr_accessible`.

```ruby
# app/models/paper_trail/version.rb
module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
    attr_accessible :author_id, :word_count, :answer
  end
end
```

If you're using [strong_parameters][18] instead of [protected_attributes][17]
then there is no need to use `attr_accessible`.

## Using a custom serializer

By default, PaperTrail stores your changes as a `YAML` dump. You can override
this with the serializer config option:

```ruby
PaperTrail.serializer = MyCustomSerializer
```

A valid serializer is a `module` (or `class`) that defines a `load` and `dump`
method.  These serializers are included in the gem for your convenience:

* [PaperTrail::Serializers::YAML][24] - Default
* [PaperTrail::Serializers::JSON][25]

### PostgreSQL JSON column type support

If you use PostgreSQL, and would like to store your `object` (and/or
`object_changes`) data in a column of [type `JSON` or type `JSONB`][26], specify
`json` instead of `text` for these columns in your migration:

```ruby
create_table :versions do |t|
  ...
  t.json :object          # Full object changes
  t.json :object_changes  # Optional column-level changes
  ...
end
```

Note: You don't need to use a particular serializer for the PostgreSQL `JSON`
column type.

#### Convert a column from text to json

Postgres' `alter column` command will not automatically convert a `text`
column to `json`, but it can still be done with plain SQL.

```sql
alter table versions
alter column object type json
using object::json;
```

## SerializedAttributes support

PaperTrail has a config option that can be used to enable/disable whether
PaperTrail attempts to utilize `ActiveRecord`'s `serialized_attributes` feature.
Note: This is enabled by default when PaperTrail is used with `ActiveRecord`
version < `4.2`, and disabled by default when used with ActiveRecord `4.2.x`.
Since `serialized_attributes` will be removed in `ActiveRecord` version `5.0`,
this configuration value has no functionality when PaperTrail is used with
version `5.0` or greater.

```ruby
# Enable support
PaperTrail.config.serialized_attributes = true
# Disable support
PaperTrail.config.serialized_attributes = false
# Get current setting
PaperTrail.serialized_attributes?
```

## Testing

You may want to turn PaperTrail off to speed up your tests.  See the [Turning
PaperTrail Off/On](#turning-papertrail-offon) section above for tips on usage
with `Test::Unit`.

### RSpec

PaperTrail provides a helper that works with [RSpec][27] to make it easier to
control when `PaperTrail` is enabled during testing.

If you wish to use the helper, you will need to require it in your RSpec test
helper like so:

```ruby
# spec/rails_helper.rb

ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
...
require 'paper_trail/frameworks/rspec'
```

When the helper is loaded, PaperTrail will be turned off for all tests by
default. When you wish to enable PaperTrail for a test you can either wrap the
test in a `with_versioning` block, or pass in `:versioning => true` option to a
spec block, like so:

```ruby
describe "RSpec test group" do
  it 'by default, PaperTrail will be turned off' do
    expect(PaperTrail).to_not be_enabled
  end

  with_versioning do
    it 'within a `with_versioning` block it will be turned on' do
      expect(PaperTrail).to be_enabled
    end
  end

  it 'can be turned on at the `it` or `describe` level like this', :versioning => true do
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
  it "is not versioned by default" do
    is_expected.to_not be_versioned
  end

  describe "add versioning to the `Widget` class" do
    before(:all) do
      class Widget < ActiveRecord::Base
        has_paper_trail
      end
    end

    it "enables paper trail" do
      is_expected.to be_versioned
    end
  end
end
```

It is also possible to do assertions on the versions using `have_a_version_with`
matcher

```
 describe '`have_a_version_with` matcher' do
    before do
      widget.update_attributes!(:name => 'Leonard', :an_integer => 1 )
      widget.update_attributes!(:name => 'Tom')
      widget.update_attributes!(:name => 'Bob')
    end

    it "is possible to do assertions on versions" do
       expect(widget).to have_a_version_with :name => 'Leonard', :an_integer => 1
       expect(widget).to have_a_version_with :an_integer => 1
       expect(widget).to have_a_version_with :name => 'Tom'
    end
  end

```

### Cucumber

PaperTrail provides a helper for [Cucumber][28] that works similar to the RSpec
helper.If you wish to use the helper, you will need to require in your cucumber
helper like so:

```ruby
# features/support/env.rb

ENV["RAILS_ENV"] ||= "cucumber"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
...
require 'paper_trail/frameworks/cucumber'
```

When the helper is loaded, PaperTrail will be turned off for all scenarios by a
`before` hook added by the helper by default. When you wish to enable PaperTrail
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

### Spork

If you wish to use the `RSpec` or `Cucumber` helpers with [Spork][29], you will
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
  ...
end
```

### Zeus or Spring

If you wish to use the `RSpec` or `Cucumber` helpers with [Zeus][30] or
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

## Testing PaperTrail

Paper Trail has facilities to test against Postgres, Mysql and SQLite. To switch
between DB engines you will need to export the DB variable for the engine you
wish to test aganist.

Though be aware we do not have the abilty to create the db's (except sqlite) for
you. You can look at .travis.yml before_script for an example of how to create
the db's needed.

```
export DB=postgres
export DB=mysql
export DB=sqlite # this is default
```

## Articles

* [Jutsu #8 - Version your RoR models with PaperTrail](http://samurails.com/gems/papertrail/),
  [Thibault](http://samurails.com/about-me/), 29th September 2014
* [Versioning with PaperTrail](http://www.sitepoint.com/versioning-papertrail),
  [Ilya Bodrov](http://www.sitepoint.com/author/ibodrov), 10th April 2014
* [Using PaperTrail to track stack traces](http://rubyrailsexpert.com/?p=36),
  T James Corcoran's blog, 1st October 2013.
* [RailsCast #255 - Undo with Paper Trail][3], Feb 28, 2011
* [RailsCast #255 - Undo with PaperTrail](http://railscasts.com/episodes/255-undo-with-paper-trail),
  28th February 2011.
* [Keep a Paper Trail with PaperTrail](http://www.linux-mag.com/id/7528),
  Linux Magazine, 16th September 2009.

## Problems

Please use GitHub's [issue tracker](http://github.com/airblade/paper_trail/issues).


## Contributors

Many thanks to:

* [Dmitry Polushkin](https://github.com/dmitry)
* [Russell Osborne](https://github.com/rposborne)
* [Zachery Hostens](http://github.com/zacheryph)
* [Jeremy Weiskotten](http://github.com/jeremyw)
* [Phan Le](http://github.com/revo)
* [jdrucza](http://github.com/jdrucza)
* [conickal](http://github.com/conickal)
* [Thibaud Guillaume-Gentil](http://github.com/thibaudgg)
* Danny Trelogan
* [Mikl Kurkov](http://github.com/mkurkov)
* [Franco Catena](https://github.com/francocatena)
* [Emmanuel Gomez](https://github.com/emmanuel)
* [Matthew MacLeod](https://github.com/mattmacleod)
* [benzittlau](https://github.com/benzittlau)
* [Tom Derks](https://github.com/EgoH)
* [Jonas Hoglund](https://github.com/jhoglund)
* [Stefan Huber](https://github.com/MSNexploder)
* [thinkcast](https://github.com/thinkcast)
* [Dominik Sander](https://github.com/dsander)
* [Burke Libbey](https://github.com/burke)
* [6twenty](https://github.com/6twenty)
* [nir0](https://github.com/nir0)
* [Eduard Tsech](https://github.com/edtsech)
* [Mathieu Arnold](https://github.com/mat813)
* [Nicholas Thrower](https://github.com/throwern)
* [Benjamin Curtis](https://github.com/stympy)
* [Peter Harkins](https://github.com/pushcx)
* [Mohd Amree](https://github.com/amree)
* [Nikita Cernovs](https://github.com/nikitachernov)
* [Jason Noble](https://github.com/jasonnoble)
* [Jared Mehle](https://github.com/jrmehle)
* [Eric Schwartz](https://github.com/emschwar)
* [Ben Woosley](https://github.com/Empact)
* [Philip Arndt](https://github.com/parndt)
* [Daniel Vydra](https://github.com/dvydra)
* [Byron Bowerman](https://github.com/BM5k)
* [Nicolas Buduroi](https://github.com/budu)
* [Pikender Sharma](https://github.com/pikender)
* [Paul Brannan](https://github.com/cout)
* [Ben Morrall](https://github.com/bmorrall)
* [Yves Senn](https://github.com/senny)
* [Ben Atkins](https://github.com/fullbridge-batkins)
* [Tyler Rick](https://github.com/TylerRick)
* [Bradley Priest](https://github.com/bradleypriest)
* [David Butler](https://github.com/dwbutler)
* [Paul Belt](https://github.com/belt)
* [Vlad Bokov](https://github.com/razum2um)
* [Sean Marcia](https://github.com/SeanMarcia)
* [Chulki Lee](https://github.com/chulkilee)
* [Lucas Souza](https://github.com/lucasas)
* [Russell Osborne](https://github.com/rposborne)
* [Ben Li](https://github.com/bli)
* [Felix Liu](https://github.com/lyfeyaj)

## Inspirations

* [Simply Versioned](http://github.com/github/simply_versioned)
* [Acts As Audited](http://github.com/collectiveidea/acts_as_audited)


## Intellectual Property

Copyright (c) 2011 Andy Stewart (boss@airbladesoftware.com).
Released under the MIT licence.

[1]: http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html
[2]: https://github.com/airblade/paper_trail/issues/163
[3]: http://railscasts.com/episodes/255-undo-with-paper-trail
[4]: https://img.shields.io/travis/airblade/paper_trail/master.svg
[5]: https://travis-ci.org/airblade/paper_trail
[6]: https://img.shields.io/gemnasium/airblade/paper_trail.svg
[7]: https://gemnasium.com/airblade/paper_trail
[9]: https://github.com/airblade/paper_trail/tree/3.0-stable
[10]: https://github.com/airblade/paper_trail/tree/2.7-stable
[11]: https://github.com/airblade/paper_trail/tree/rails2
[12]: http://www.sinatrarb.com
[13]: https://github.com/janko-m/sinatra-activerecord
[14]: https://raw.github.com/airblade/paper_trail/master/lib/generators/paper_trail/templates/create_versions.rb
[15]: http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style
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
