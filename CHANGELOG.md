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
