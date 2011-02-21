# PaperTrail

PaperTrail lets you track changes to your models' data.  It's good for auditing or versioning.  You can see how a model looked at any stage in its lifecycle, revert it to any version, and even undelete it after it's been destroyed.


## Features

* Stores every create, update and destroy.
* Does not store updates which don't change anything.
* Does not store updates which only change attributes you are ignoring.
* Allows you to get at every version, including the original, even once destroyed.
* Allows you to get at every version even if the schema has since changed.
* Allows you to get at the version as of a particular time.
* Automatically restores the `has_one` associations as they were at the time.
* Automatically records who was responsible via your controller.  PaperTrail calls `current_user` by default, if it exists, but you can have it call any method you like.
* Allows you to set who is responsible at model-level (useful for migrations).
* Allows you to store arbitrary model-level metadata with each version (useful for filtering versions).
* Allows you to store arbitrary controller-level information with each version, e.g. remote IP.
* Can be turned off/on per class (useful for migrations).
* Can be turned off/on globally (useful for testing).
* No configuration necessary.
* Stores everything in a single database table (generates migration for you).
* Thoroughly tested.
* Threadsafe.


## Rails Version

Works on Rails 3 and Rails 2.3.  The Rails 3 code is on the master branch and tagged v2.x.  The Rails 2.3 code is on the Rails 2 branch and tagged 1.x.


## API Summary

When you declare `has_paper_trail` in your model, you get these methods:

    class Widget < ActiveRecord::Base
      has_paper_trail   # you can pass various options here
    end

    # Returns this widget's versions.
    widget.versions

    # Return the version this widget was reified from, or nil if it is live.
    widget.version

    # Returns true if this widget is the current, live one; or false if it is from a previous version.
    widget.live?

    # Returns who put the widget into its current state.
    widget.originator

    # Returns the widget (not a version) as it looked at the given timestamp.
    widget.version_at(timestamp)

    # Returns the widget (not a version) as it was most recently.
    widget.previous_version

    # Returns the widget (not a version) as it became next.
    widget.next_version

    # Turn PaperTrail off for all widgets.
    Widget.paper_trail_off

    # Turn PaperTrail on for all widgets.
    Widget.paper_trail_on

And a `Version` instance has these methods:

    # Returns the item restored from this version.
    version.reify(options = {})

    # Returns who put the item into the state stored in this version.
    version.originator

    # Returns who changed the item from the state it had in this version.
    version.terminator
    version.whodunnit

    # Returns the next version.
    version.next

    # Returns the previous version.
    version.previous

    # Returns the index of this version in all the versions.
    version.index

    # Returns the event that caused this version (create|update|destroy).
    version.event

In your controllers you can override these methods:

    # Returns the user who is responsible for any changes that occur.
    # Defaults to current_user.
    user_for_paper_trail

    # Returns any information about the controller or request that you want
    # PaperTrail to store alongside any changes that occur.
    info_for_paper_trail


## Basic Usage

PaperTrail is simple to use.  Just add 15 characters to a model to get a paper trail of every `create`, `update`, and `destroy`.

    class Widget < ActiveRecord::Base
      has_paper_trail
    end

This gives you a `versions` method which returns the paper trail of changes to your model.

    >> widget = Widget.find 42
    >> widget.versions             # [<Version>, <Version>, ...]

Once you have a version, you can find out what happened:

    >> v = widget.versions.last
    >> v.event                     # 'update' (or 'create' or 'destroy')
    >> v.whodunnit                 # '153'  (if the update was via a controller and
                                   #         the controller has a current_user method,
                                   #         here returning the id of the current user)
    >> v.created_at                # when the update occurred
    >> widget = v.reify            # the widget as it was before the update;
                                   # would be nil for a create event

PaperTrail stores the pre-change version of the model, unlike some other auditing/versioning plugins, so you can retrieve the original version.  This is useful when you start keeping a paper trail for models that already have records in the database.

    >> widget = Widget.find 153
    >> widget.name                                 # 'Doobly'

    # Add has_paper_trail to Widget model.

    >> widget.versions                             # []
    >> widget.update_attributes :name => 'Wotsit'
    >> widget.versions.first.reify.name            # 'Doobly'
    >> widget.versions.first.event                 # 'update'

This also means that PaperTrail does not waste space storing a version of the object as it currently stands.  The `versions` method gives you previous versions; to get the current one just call a finder on your `Widget` model as usual.

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
    <td>widget'</td>
  <tr>
    <td>destroy</td>
    <td>widget</td>
    <td>nil</td>
  </tr>
</table>

PaperTrail stores the values in the Model Before column.  Most other auditing/versioning plugins store the After column.


## Ignoring changes to certain attributes

You can ignore changes to certain attributes like this:

    class Article < ActiveRecord::Base
      has_paper_trail :ignore => [:title, :rating]
    end

This means that changes to just the `title` or `rating` will not store another version of the article.  It does not mean that the `title` and `rating` attributes will be ignored if some other change causes a new `Version` to be crated.  For example:

    >> a = Article.create
    >> a.versions.length                         # 1
    >> a.update_attributes :title => 'My Title', :rating => 3
    >> a.versions.length                         # 1
    >> a.update_attributes :content => 'Hello'
    >> a.versions.length                         # 2
    >> a.versions.last.reify.title               # 'My Title'


## Reverting And Undeleting A Model

PaperTrail makes reverting to a previous version easy:

    >> widget = Widget.find 42
    >> widget.update_attributes :name => 'Blah blah'
    # Time passes....
    >> widget = widget.versions.last.reify  # the widget as it was before the update
    >> widget.save                          # reverted

Alternatively you can find the version at a given time:

    >> widget = widget.version_at(1.day.ago)  # the widget as it was one day ago
    >> widget.save                            # reverted

Note `version_at` gives you the object, not a version, so you don't need to call `reify`.

Undeleting is just as simple:

    >> widget = Widget.find 42
    >> widget.destroy
    # Time passes....
    >> widget = Version.find(153).reify    # the widget as it was before it was destroyed
    >> widget.save                         # the widget lives!

In fact you could use PaperTrail to implement an undo system, though I haven't had the opportunity yet to do it myself.


## Navigating Versions

You can call `previous_version` and `next_version` on an item to get it as it was/became.  Note that these methods reify the item for you.

    >> widget = Widget.find 42
    >> widget.versions.length              # 4 for example
    >> widget = widget.previous_version    # => widget == widget.versions.last.reify
    >> widget = widget.previous_version    # => widget == widget.versions[-2].reify
    >> widget.next_version                 # => widget == widget.versions.last.reify
    >> widget.next_version                 # nil

As an aside, I'm undecided about whether `widget.versions.last.next_version` should return `nil` or `self` (i.e. `widget`).  Let me know if you have a view.

If instead you have a particular `version` of an item you can navigate to the previous and next versions.

    >> widget = Widget.find 42
    >> version = widget.versions[-2]    # assuming widget has several versions
    >> previous = version.previous
    >> next = version.next

You can find out which of an item's versions yours is:

    >> current_version_number = version.index    # 0-based

Finally, if you got an item by reifying one of its versions, you can navigate back to the version it came from:

    >> latest_version = Widget.find(42).versions.last
    >> widget = latest_version.reify
    >> widget.version == latest_version    # true

You can find out whether a model instance is the current, live one -- or whether it came instead from a previous version -- with `live?`:

    >> widget = Widget.find 42
    >> widget.live?                        # true
    >> widget = widget.versions.last.reify
    >> widget.live?                        # false


## Finding Out Who Was Responsible For A Change

If your `ApplicationController` has a `current_user` method, PaperTrail will store the value it returns in the `version`'s `whodunnit` column.  Note that this column is a string so you will have to convert it to an integer if it's an id and you want to look up the user later on:

    >> last_change = Widget.versions.last
    >> user_who_made_the_change = User.find last_change.whodunnit.to_i

You may want PaperTrail to call a different method to find out who is responsible.  To do so, override the `user_for_paper_trail` method in your controller like this:

    class ApplicationController
      def user_for_paper_trail
        logged_in? ? current_member : 'Public user'  # or whatever
      end
    end

In a migration or in `script/console` you can set who is responsible like this:

    >> PaperTrail.whodunnit = 'Andy Stewart'
    >> widget.update_attributes :name => 'Wibble'
    >> widget.versions.last.whodunnit              # Andy Stewart

N.B. A `version`'s `whodunnit` records who changed the object causing the `version` to be stored.  Because a `version` stores the object as it looked before the change (see the table above), `whodunnit` returns who stopped the object looking like this -- not who made it look like this.  Hence `whodunnit` is aliased as `terminator`.

To find out who made a `version`'s object look that way, use `version.originator`.  And to find out who made a "live" object look like it does, use `originator` on the object.

    >> widget = Widget.find 153                    # assume widget has 0 versions
    >> PaperTrail.whodunnit = 'Alice'
    >> widget.update_attributes :name => 'Yankee'
    >> widget.originator                           # 'Alice'
    >> PaperTrail.whodunnit = 'Bob'
    >> widget.update_attributes :name => 'Zulu'
    >> widget.originator                           # 'Bob'
    >> first_version, last_version = widget.versions.first, widget.versions.last
    >> first_version.whodunnit                     # 'Alice'
    >> first_version.originator                    # nil
    >> first_version.terminator                    # 'Alice'
    >> last_version.whodunnit                      # 'Bob'
    >> last_version.originator                     # 'Alice'
    >> last_version.terminator                     # 'Bob'


## Has-One Associations

PaperTrail automatically restores `:has_one` associations as they were at (actually, 3 seconds before) the time.

    class Treasure < ActiveRecord::Base
      has_one :location
    end

    >> treasure.amount                  # 100
    >> treasure.location.latitude       # 12.345

    >> treasure.update_attributes :amount => 153
    >> treasure.location.update_attributes :latitude => 54.321
    
    >> t = treasure.versions.last.reify
    >> t.amount                         # 100
    >> t.location.latitude              # 12.345

The implementation is complicated by the edge case where the parent and child are updated in one go, e.g. in one web request or database transaction.  PaperTrail doesn't know about different models being updated "together", so you can't ask it definitively to get the child as it was before the joint parent-and-child update.

The correct solution is to make PaperTrail aware of requests or transactions (c.f. [Efficiency's transaction ID middleware](http://github.com/efficiency20/ops_middleware/blob/master/lib/e20/ops/middleware/transaction_id_middleware.rb)).  In the meantime we work around the problem by finding the child as it was a few seconds before the parent was updated.  By default we go 3 seconds before but you can change this by passing the `:has_one` option to `reify`:

    >> t = treasure.versions.last.reify(:has_one => 1)       # look back 1 second instead of 3

If you are shuddering, take solace from knowing you can opt out of these shenanigans:

    >> t = treasure.versions.last.reify(:has_one => false)   # I say no to "workarounds"!

Opting out means your `:has_one` associated objects will be the live ones, not the ones the user saw at the time.  Since PaperTrail doesn't auto-restore `:has_many` associations (I can't get it to work) or `:belongs_to` (I ran out of time looking at `:has_many`), this at least makes your associations wrong consistently ;)



## Has-Many-Through Associations

PaperTrail can track most changes to the join table.  Specifically it can track all additions but it can only track removals which fire the `after_destroy` callback on the join table.  Here are some examples:

Given these models:

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

Then each of the following will store authorship versions:

    >> @book.authors << @dostoyevsky
    >> @book.authors.create :name => 'Tolstoy'
    >> @book.authorships.last.destroy
    >> @book.authorships.clear

But none of these will:

    >> @book.authors.delete @tolstoy
    >> @book.author_ids = [@solzhenistyn.id, @dostoyevsky.id]
    >> @book.authors = []

Having said that, you can apparently get all these working (I haven't tested it myself) with this [monkey patch](http://stackoverflow.com/questions/2381033/how-to-create-a-full-audit-log-in-rails-for-every-table/2381411#2381411):

    # In config/initializers/core_extensions.rb or lib/core_extensions.rb
    ActiveRecord::Associations::HasManyThroughAssociation.class_eval do 
      def delete_records(records)
        klass = @reflection.through_reflection.klass
        records.each do |associate|
          klass.destroy_all(construct_join_attributes(associate))
        end
      end
    end

The difference is the call to `destroy_all` instead of `delete_all` in [the original](http://github.com/rails/rails/blob/master/activerecord/lib/active_record/associations/has_many_through_association.rb#L76-81).
    

There may be a way to store authorship versions, probably using association callbacks, no matter how the collection is manipulated but I haven't found it yet.  Let me know if you do.


## Storing metadata

You can store arbitrary model-level metadata alongside each version like this:

    class Article < ActiveRecord::Base
      belongs_to :author
      has_paper_trail :meta => { :author_id  => Proc.new { |article| article.author_id },
                                 :word_count => :count_words,
                                 :answer     => 42 }
      def count_words
        153
      end
    end

PaperTrail will call your proc with the current article and store the result in the `author_id` column of the `versions` table.  (Remember to add your metadata columns to the table.)

Why would you do this?  In this example, `author_id` is an attribute of `Article` and PaperTrail will store it anyway in serialized (YAML) form in the `object` column of the `version` record.  But let's say you wanted to pull out all versions for a particular author; without the metadata you would have to deserialize (reify) each `version` object to see if belonged to the author in question.  Clearly this is inefficient.  Using the metadata you can find just those versions you want:

    Version.all(:conditions => ['author_id = ?', author_id])

Note you can pass a symbol as a value in the `meta` hash to signal a method to call.

You can also store any information you like from your controller.  Just override the `info_for_paper_trail` method in your controller to return a hash whose keys correspond to columns in your `versions` table.  E.g.:

    class ApplicationController
      def info_for_paper_trail
        { :ip => request.remote_ip, :user_agent => request.user_agent }
      end
    end

Remember to add those extra columns to your `versions` table ;)


## Diffing Versions

When you're storing every version of an object, as PaperTrail lets you do, you're almost certainly going to want to diff those versions against each other.  However I haven't built a diff method into PaperTrail because I think diffing is best left to dedicated libraries, and also it's hard to come up with a diff method to suit all the use cases.

You might be surprised that PaperTrail doesn't use diffs internally anyway.  When I designed PaperTrail I wanted simplicity and robustness so I decided to make each version of an object self-contained.  A version stores all of its object's data, not a diff from the previous version.

So instead here are some specialised diffing libraries which you can use on top of PaperTrail.

For diffing two strings:

* [htmldiff](http://github.com/myobie/htmldiff): expects but doesn't require HTML input and produces HTML output.  Works very well but slows down significantly on large (e.g. 5,000 word) inputs.
* [differ](http://github.com/pvande/differ): expects plain text input and produces plain text/coloured/HTML/any output.  Can do character-wise, word-wise, line-wise, or arbitrary-boundary-string-wise diffs.  Works very well on non-HTML input.
* [diff-lcs](http://github.com/halostatue/ruwiki/tree/master/diff-lcs/trunk): old-school, line-wise diffs.

For diffing two ActiveRecord objects:

* [Jeremy Weiskotten's PaperTrail fork](http://github.com/jeremyw/paper_trail/blob/master/lib/paper_trail/has_paper_trail.rb#L151-156): uses ActiveSupport's diff to return an array of hashes of the changes.
* [activerecord-diff](http://github.com/tim/activerecord-diff): rather like ActiveRecord::Dirty but also allows you to specify which columns to compare.


## Turning PaperTrail Off/On

Sometimes you don't want to store changes.  Perhaps you are only interested in changes made by your users and don't need to store changes you make yourself in, say, a migration -- or when testing your application.

If you are about change some widgets and you don't want a paper trail of your changes, you can turn PaperTrail off like this:

    >> Widget.paper_trail_off

And on again like this:

    >> Widget.paper_trail_on

You can also disable PaperTrail for all models:

    >> PaperTrail.enabled = false

For example, you might want to disable PaperTrail in your Rails application's test environment to speed up your tests.  This will do it:

    # in config/environments/test.rb
    config.after_initialize do
      PaperTrail.enabled = false
    end

If you disable PaperTrail in your test environment but want to enable it for specific tests, you can add a helper like this to your test helper:

    # in test/test_helper.rb
    def with_versioning
      was_enabled = PaperTrail.enabled?
      PaperTrail.enabled = true
      begin
        yield
      ensure
        PaperTrail.enabled = was_enabled
      end
    end

And then use it in your tests like this:

    test "something that needs versioning" do
      with_versioning do
        # your test
      end
    end


## Deleting Old Versions

Over time your `versions` table will grow to an unwieldy size.  Because each version is self-contained (see the Diffing section above for more) you can simply delete any records you don't want any more.  For example:

    sql> delete from versions where created_at < 2010-06-01;

    >> Version.delete_all ["created_at < ?", 1.week.ago]


## Installation

### Rails 3

Please see the `master` branch.

### Rails 2

1. Install PaperTrail as a gem via your `config/environment.rb`:

    `config.gem 'paper_trail', :version => '~> 1'`

2. Generate a migration which will add a `versions` table to your database.

    `script/generate paper_trail`

3. Run the migration.

    `rake db:migrate`

4. Add `has_paper_trail` to the models you want to track.


## Testing

PaperTrail uses Bundler to manage its dependencies (in development and testing).  You can run the tests with `bundle exec rake test`.  (You may need to `bundle install` first.)


## Articles

[Keep a Paper Trail with PaperTrail](http://www.linux-mag.com/id/7528), Linux Magazine, 16th September 2009.


## Problems

Please use GitHub's [issue tracker](http://github.com/airblade/paper_trail/issues).


## Contributors

Many thanks to:

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


## Inspirations

* [Simply Versioned](http://github.com/github/simply_versioned)
* [Acts As Audited](http://github.com/collectiveidea/acts_as_audited)


## Intellectual Property

Copyright (c) 2011 Andy Stewart (boss@airbladesoftware.com).
Released under the MIT licence.
