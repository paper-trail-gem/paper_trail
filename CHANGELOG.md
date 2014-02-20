## 3.0.1 (Unreleased)

  - [#328](https://github.com/airblade/paper_trail/pull/328) / [#326](https://github.com/airblade/paper_trail/issues/326)/
    [#307](https://github.com/airblade/paper_trail/issues/307) - `Model.paper_trail_enabled_for_model?` and
    `model_instance.without_versioning` is now thread-safe.
  - [#316](https://github.com/airblade/paper_trail/issues/316) - `user_for_paper_trail` should default to `current_user.try(:id)`
    instead of `current_user` (if `current_user` is defined).
  - [#313](https://github.com/airblade/paper_trail/pull/313) - Make the `Rails::Controller` helper compatible with
    `ActionController::API` for compatibility with the [`rails-api`](https://github.com/rails-api/rails-api) gem.
  - Deprecated `Model.paper_trail_on` and `Model.paper_trail_off` in favor of bang versions of the methods. Deprecation warning
    informs users that the non-bang versions of the methods will be removed in version `3.1.0`.

## 3.0.0

  - [#305](https://github.com/airblade/paper_trail/pull/305) - `PaperTrail::VERSION` should be loaded at runtime.
  - [#295](https://github.com/airblade/paper_trail/issues/295) - Explicitly specify table name for version class when
    querying attributes. Prevents `AmbiguousColumn` errors on certain `JOIN` statements.
  - [#289](https://github.com/airblade/paper_trail/pull/289) - Use `ActiveSupport::Concern` for implementation of base functionality on
    `PaperTrail::Version` class. Increases flexibility and makes it easier to use custom version classes with multiple `ActiveRecord` connections.
  - [#288](https://github.com/airblade/paper_trail/issues/288) - Change all scope declarations to class methods on the `PaperTrail::Version`
    class. Fixes usability when `PaperTrail::Version.abstract_class? == true`.
  - [#287](https://github.com/airblade/paper_trail/issues/287) - Support for
    [PostgreSQL's JSON Type](http://www.postgresql.org/docs/9.2/static/datatype-json.html) for storing `object` and `object_changes`.
  - [#281](https://github.com/airblade/paper_trail/issues/281) - `Rails::Controller` helper will return `false` for the
    `paper_trail_enabled_for_controller` method if `PaperTrail.enabled? == false`.
  - [#280](https://github.com/airblade/paper_trail/pull/280) - Don't track virtual timestamp attributes.
  - [#278](https://github.com/airblade/paper_trail/issues/278)/[#272](https://github.com/airblade/paper_trail/issues/272) -
    Make RSpec and Cucumber helpers usable with [Spork](https://github.com/sporkrb/spork) and [Zeus](https://github.com/burke/zeus).
  - [#273](https://github.com/airblade/paper_trail/pull/273) - Make the `only` and `ignore` options accept `Hash` arguments;
    allows for conditional tracking.
  - [#264](https://github.com/airblade/paper_trail/pull/264) - Allow unwrapped symbol to be passed in to the `on` option.
  - [#224](https://github.com/airblade/paper_trail/issues/224)/[#236](https://github.com/airblade/paper_trail/pull/236) -
    Fixed compatibility with [ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on).
  - [#235](https://github.com/airblade/paper_trail/pull/235) - Dropped unnecessary secondary sort on `versions` association.
  - [#216](https://github.com/airblade/paper_trail/pull/216) - Added helper & extension for [RSpec](https://github.com/rspec/rspec),
    and helper for [Cucumber](http://cukes.info).
  - [#212](https://github.com/airblade/paper_trail/pull/212) - Added `PaperTrail::Cleaner` module, useful for discarding draft versions.
  - [#207](https://github.com/airblade/paper_trail/issues/207) - Versions for `'create'` events are now created with `create!` instead of 
    `create` so that an exception gets raised if it is appropriate to do so.
  - [#199](https://github.com/airblade/paper_trail/pull/199) - Rails 4 compatibility.
  - [#165](https://github.com/airblade/paper_trail/pull/165) - Namespaced the `Version` class under the `PaperTrail` module.
  - [#119](https://github.com/airblade/paper_trail/issues/119) - Support for [Sinatra](http://www.sinatrarb.com/); decoupled gem from `Rails`.
  - Renamed the default serializers from `PaperTrail::Serializers::Yaml` and `PaperTrail::Serializers::Json` to the capitalized forms,
    `PaperTrail::Serializers::YAML` and `PaperTrail::Serializers::JSON`.
  - Removed deprecated `set_whodunnit` method from Rails Controller scope.

## 2.7.2

  - [#228](https://github.com/airblade/paper_trail/issues/228) - Refactored default `user_for_paper_trail` method implementation
    so that `current_user` only gets invoked if it is defined.
  - [#219](https://github.com/airblade/paper_trail/pull/219) - Fixed issue where attributes stored with `nil` value might not get
    reified properly depending on the way the serializer worked.
  - [#213](https://github.com/airblade/paper_trail/issues/213) - Added a `version_limit` option to the `PaperTrail::Config` options
    that can be used to restrict the number of versions PaperTrail will store per object instance.
  - [#187](https://github.com/airblade/paper_trail/pull/187) - Confirmed JRuby support.
  - [#174](https://github.com/airblade/paper_trail/pull/174) - The `event` field on the versions table can now be customized.

## 2.7.1

  - [#206](https://github.com/airblade/paper_trail/issues/206) - Fixed Ruby 1.8.7 compatibility for tracking `object_changes`.
  - [#200](https://github.com/airblade/paper_trail/issues/200) - Fixed `next_version` method so that it returns the live model
    when called on latest reified version of a model prior to the live model.
  - [#197](https://github.com/airblade/paper_trail/issues/197) - PaperTrail now falls back on using YAML for serialization of
    serialized model attributes for storage in the `object` and `object_changes` columns in the `Version` table. This fixes
    compatibility for `Rails 3.0.x` for projects that employ the `serialize` declaration on a model.
  - [#194](https://github.com/airblade/paper_trail/issues/194) - A JSON serializer is now included in the gem.
  - [#192](https://github.com/airblade/paper_trail/pull/192) - `object_changes` should store serialized representation of serialized
    attributes for `create` actions (in addition to `update` actions, which had already been patched by
    [#180](https://github.com/airblade/paper_trail/pull/180)).
  - [#190](https://github.com/airblade/paper_trail/pull/190) - Fixed compatibility with
    [SerializedAttributes](https://github.com/technoweenie/serialized_attributes) gem.
  - [#189](https://github.com/airblade/paper_trail/pull/189) - Provided support for a `configure` block initializer.
  - Added `setter` method for the `serializer` config option.

## 2.7.0

  - [#183](https://github.com/airblade/paper_trail/pull/183) - Fully qualify the `Version` class to help prevent
    namespace resolution errors within other gems / plugins.
  - [#180](https://github.com/airblade/paper_trail/pull/180) - Store serialized representation of serialized attributes
    on the `object` and `object_changes` columns in the `Version` table.
  - [#164](https://github.com/airblade/paper_trail/pull/164) - Allow usage of custom serializer for storage of object attributes.

## 2.6.4

  - [#181](https://github.com/airblade/paper_trail/issues/181)/[#182](https://github.com/airblade/paper_trail/pull/182) -
    Controller metadata methods should only be evaluated when `paper_trail_enabled_for_controller == true`.
  - [#177](https://github.com/airblade/paper_trail/issues/177)/[#178](https://github.com/airblade/paper_trail/pull/178) -
    Factored out `version_key` into it's own method to prevent `ConnectionNotEstablished` error from getting thrown in
    instances where `has_paper_trail` is declared on class prior to ActiveRecord establishing a connection.
  - [#176](https://github.com/airblade/paper_trail/pull/176) - Force metadata calls for attributes to use current value
    if attribute value is changing.
  - [#173](https://github.com/airblade/paper_trail/pull/173) - Update link to [diff-lcs](https://github.com/halostatue/diff-lcs).
  - [#172](https://github.com/airblade/paper_trail/pull/172) - Save `object_changes` on creation.
  - [#168](https://github.com/airblade/paper_trail/pull/168) - Respect conditional `:if` or `:unless` arguments to the
    `has_paper_trail` method for `destroy` events.
  - [#167](https://github.com/airblade/paper_trail/pull/167) - Fix `originator` method so that it works with subclasses and STI.
  - [#160](https://github.com/airblade/paper_trail/pull/160) - Fixed failing tests and resolved out of date dependency issues.
  - [#157](https://github.com/airblade/paper_trail/pull/157) - Refactored `class_attribute` names on the `ClassMethods` module
    for names that are not obviously pertaining to PaperTrail to prevent method name collision.
