# PaperTrail

PaperTrail lets you track changes to your models' data.  It's good for auditing or versioning.  You can see how a model looked at any stage in its lifecycle, revert it to any version, and even undelete it after it's been destroyed.


## Features

* Stores every create, update and destroy.
* Does not store updates which don't change anything (or which only change attributes you are ignoring).
* Allows you to get at every version, including the original, even once destroyed.
* Allows you to get at every version even if the schema has since changed.
* Automatically records who was responsible if your controller has a `current_user` method.
* Allows you to set who is responsible at model-level (useful for migrations).
* Can be turned off/on (useful for migrations).
* No configuration necessary.
* Stores everything in a single database table (generates migration for you).
* Thoroughly tested.


## Rails Version

Known to work on Rails 2.3.  Probably works on Rails 2.2 and 2.1.


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

Undeleting is just as simple:

    >> widget = Widget.find 42
    >> widget.destroy
    # Time passes....
    >> widget = Version.find(153).reify    # the widget as it was before it was destroyed
    >> widget.save                         # the widget lives!

In fact you could use PaperTrail to implement an undo system, though I haven't had the opportunity yet to do it myself.


## Finding Out Who Was Responsible For A Change

If your `ApplicationController` has a `current_user` method, PaperTrail will store the value it returns in the `version`'s `whodunnit` column.  Note that this column is a string so you will have to convert it to an integer if it's an id and you want to look up the user later on:

    >> last_change = Widget.versions.last
    >> user_who_made_the_change = User.find last_change.whodunnit.to_i

In a migration or in `script/console` you can set who is responsible like this:

    >> PaperTrail.whodunnit = 'Andy Stewart'
    >> widget.update_attributes :name => 'Wibble'
    >> widget.versions.last.whodunnit              # Andy Stewart


## Turning PaperTrail Off/On

Sometimes you don't want to store changes.  Perhaps you are only interested in changes made
by your users and don't need to store changes you make yourself in, say, a migration.

If you are about change some widgets and you don't want a paper trail of your changes, you can
turn PaperTrail off like this:

    >> Widget.paper_trail_off

And on again like this:

    >> Widget.paper_trail_on


## Installation

1. Install PaperTrail either as a gem or as a plugin:

    `config.gem 'airblade-paper_trail', :lib => 'paper_trail', :source => 'http://gems.github.com'`

    or:

    `script/plugin install git://github.com/airblade/paper_trail.git`

2. Generate a migration which will add a `versions` table to your database.

    `script/generate paper_trail`

3. Run the migration.

    `rake db:migrate`

4. Add `has_paper_trail` to the models you want to track.


## Testing

PaperTrail has a thorough suite of tests.  Thanks to [Zachery Hostens](http://github.com/zacheryph) for making them able to run standalone, i.e. without needing PaperTrail to be sitting in a Rails app.


## Problems

Please use GitHub's [issue tracker](http://github.com/airblade/paper_trail/issues).


## Contributors

Many thanks to:

* [Zachery Hostens](http://github.com/zacheryph)


## Inspirations

* [Simply Versioned](http://github.com/github/simply_versioned)
* [Acts As Audited](http://github.com/collectiveidea/acts_as_audited)


## Intellectual Property

Copyright (c) 2009 Andy Stewart (boss@airbladesoftware.com).
Released under the MIT licence.
