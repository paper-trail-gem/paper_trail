# Changelog

This project follows [semver 2.0.0](http://semver.org/spec/v2.0.0.html) and the
recommendations of [keepachangelog.com](http://keepachangelog.com/).

## Unreleased

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1458](https://github.com/paper-trail-gem/paper_trail/pull/1416) - Fix serializing
  of time/date columns using yaml serializer. Previously, these were serialized as ruby
  objects which uses a lot of space. Now they are serialized into strings.

## 15.1.0 (2023-10-22)

### Breaking Changes

- None

### Fixed

- None

### Dependencies

- Add support for Rails 7.1
- Add support for Ruby 3.2

## 15.0.0 (2023-08-06)

### Breaking Changes

- None

### Added

- [#1416](https://github.com/paper-trail-gem/paper_trail/pull/1416) - Adds a
  model-configurable option `synchronize_version_creation_timestamp` which, if
  set to false, opts out of synchronizing timestamps between `Version.created_at`
  and the record's `updated_at`.

### Fixed

- [#1422](https://github.com/paper-trail-gem/paper_trail/pull/1422) - Fix the
  issue that unencrypted plaintext values are versioned with ActiveRecord
  encryption (since Rails 7) when using JSON serialization on PostgreSQL json
  columns.
- [#1414](https://github.com/paper-trail-gem/paper_trail/pull/1414) - When
  generating the migration, the version table will use uuid as primary key type
  if `--uuid` flag is specified.

### Dependencies

- Drop support for Rails 6.0, which [reached EoL on 2023-06-01][2]
- Drop support for Ruby 2.7, which [reached EoL on 2023-03-31][3]

## 14.0.0 (2022-11-26)

### Breaking Changes

- [#1399](https://github.com/paper-trail-gem/paper_trail/pull/1399) - Same
  change re: `YAML.safe_load` as in 13.0.0, but this time for Rails 6.0 and 6.1.
  - This change only affects users whose `versions` table has `object` or
    `object_changes` columns of type `text`, and who use the YAML serializer. People
    who use the JSON serializer, or those with `json(b)` columns, are unaffected.
  - Please see [doc/pt_13_yaml_safe_load.md](doc/pt_13_yaml_safe_load.md) for details.
- [#1406](https://github.com/paper-trail-gem/paper_trail/pull/1406) -
  Certain [Metadata][1] keys are now forbidden, like `id`, and `item_type`.
  These keys are reserved by PT.
  - This change is unlikely to affect anyone. It is not expected that anyone
    uses these metadata keys. Most people probably don't use PT metadata at all.

### Dependencies

- Drop support for Rails 5.2, which reached EoL on 2022-06-01
- Drop support for Ruby 2.6, which reached EoL on 2022-03-31
- Drop support for request_store < 1.4

### Added

- None

### Fixed

- [#1395](https://github.com/paper-trail-gem/paper_trail/issues/1395) -
  Fix incorrect `Version#created_at` value when using
  `PaperTrail::RecordTrail#update_columns`
- [#1404](https://github.com/paper-trail-gem/paper_trail/pull/1404) -
  Delay referencing ActiveRecord until after Railtie is loaded
- Where possible, methods which are not part of PaperTrail's public API have
  had their access changed to private. All of these methods had been clearly
  marked as `@api private` in the documentation, for years. This is not expected
  to be a breaking change.

## 13.0.0 (2022-08-15)

### Breaking Changes

- For Rails >= 7.0, the default serializer will now use `YAML.safe_load` unless
  `ActiveRecord.use_yaml_unsafe_load`. This change only affects users whose
  `versions` table has `object` or `object_changes` columns of type `text`, and
  who use the YAML serializer. People who use the JSON serializer, or those with
  `json(b)` columns, are unaffected. Please see
  [doc/pt_13_yaml_safe_load.md](doc/pt_13_yaml_safe_load.md) for details.

### Added

- None

### Fixed

- None

## 12.3.0 (2022-03-13)

### Breaking Changes

- None

### Added

- [#1371](https://github.com/paper-trail-gem/paper_trail/pull/1371) - Added
  `in_after_callback` argument to `PaperTrail::RecordTrail#save_with_version`,
  to allow the caller to indicate if this method is being called during an
  `after` callback. Defaults to `false`.
- [#1374](https://github.com/paper-trail-gem/paper_trail/pull/1374) - Added
  option `--uuid` when generating new migration. This can be used to set the
  type of item_id column to uuid for use with paper_trail on a database that
  uses uuid as primary key.

### Fixed

- [#1373](https://github.com/paper-trail-gem/paper_trail/issues/1373) - Add
  CLI option to use uuid type for item_id when generating migration.
- [#1376](https://github.com/paper-trail-gem/paper_trail/pull/1376) - Create a
  version record when associated object is touched. Restores the behavior of
  PaperTrail < v12.1.0.

## 12.2.0 (2022-01-21)

### Breaking Changes

- None

### Added

- [#1365](https://github.com/paper-trail-gem/paper_trail/pull/1365) -
  Support Rails 7.0
- [#1349](https://github.com/paper-trail-gem/paper_trail/pull/1349) -
  `if:` and `unless:` work with `touch` events now.

### Fixed

- [#1366](https://github.com/paper-trail-gem/paper_trail/pull/1366) -
  Fixed a bug where the `create_versions` migration lead to a broken `db/schema.rb` for Ruby 3

### Dependencies

- [#1338](https://github.com/paper-trail-gem/paper_trail/pull/1338) -
  Support Psych version 4
- ruby >= 2.6 (was >= 2.5). Ruby 2.5 reached EoL on 2021-03-31.

## 12.1.0 (2021-08-30)

### Breaking Changes

- None

### Added

- [#1292](https://github.com/paper-trail-gem/paper_trail/pull/1292) -
  `where_attribute_changes` queries for versions where the object's attribute
  changed to or from any values.
- [#1291](https://github.com/paper-trail-gem/paper_trail/pull/1291) -
  `where_object_changes_to` queries for versions where the object's attributes
  changed to one set of known values from any other set of values.

### Fixed

- [#1285](https://github.com/paper-trail-gem/paper_trail/pull/1285) -
  For ActiveRecord >= 6.0, the `touch` callback will no longer create a new
  `Version` for skipped or ignored attributes.
- [#1309](https://github.com/paper-trail-gem/paper_trail/pull/1309) -
  Removes `item_subtype` requirement when specifying model-specific limits.
- [#1333](https://github.com/paper-trail-gem/paper_trail/pull/1333) -
  Improve reification of STI models that use `find_sti_class`/`sti_class_for`
  to customize single table inheritance.

## 12.0.0 (2021-03-29)

### Breaking Changes

- [#1281](https://github.com/paper-trail-gem/paper_trail/pull/1281) Rails:
  Instead of an `Engine`, PT now provides a `Railtie`, which is simpler.
  This was not expected to be a breaking change, but has caused trouble for
  some people:
  - Issue with the deprecated `autoloader = :classic` setting
    (https://github.com/paper-trail-gem/paper_trail/issues/1305)
- Rails: The deprecated `config.paper_trail` configuration technique
  has been removed. This configuration object was deprecated in 10.2.0. It only
  had one key, `config.paper_trail.enabled`. Please review docs section [2.d.
  Turning PaperTrail
  Off](https://github.com/paper-trail-gem/paper_trail/#2d-turning-papertrail-off)
  for alternatives.

### Added

- `where_object_changes_from` queries for versions where the object's attributes
  changed from one set of known values to any other set of values.

### Fixed

- [#1281](https://github.com/paper-trail-gem/paper_trail/pull/1281) Rails:
  Instead of an `Engine`, PT now provides a `Railtie`, which is simpler.
- Expand kwargs passed to `save_with_version` using double splat operator - Rails 6.1 compatibility
- [#1287](https://github.com/paper-trail-gem/paper_trail/issues/1287) - Fix 'rails db:migrate' error when run against an app with mysql2 adapter

### Dependencies

- Drop support for ruby 2.4 (reached EoL on 2020-03-31)

## 11.1.0 (2020-12-16)

### Breaking Changes

- None

### Added

- [#1272](https://github.com/paper-trail-gem/paper_trail/issues/1272) -
  Rails 6.1 compatibility

### Fixed

- None

## 11.0.0 (2020-08-24)

### Breaking Changes

- [#1221](https://github.com/paper-trail-gem/paper_trail/pull/1221)
  If you use the experimental association-tracking feature, and you forget to
  install the `paper_trail-association_tracking` gem, then, when you call
  `track_associations=` you will get a `NoMethodError` instead of the previous
  detailed error. Normally the removal of such a temporary warning would not be
  treated as a breaking change, but since this relates to PT-AT, it seemed
  warranted.
- `VersionConcern#sibling_versions` is now private, and its arity has changed.

### Added

- None

### Fixed

- [#1242](https://github.com/paper-trail-gem/paper_trail/issues/1242) -
  Generator make wrong migration for Oracle database

- [#1238](https://github.com/paper-trail-gem/paper_trail/pull/1238) -
  Query optimization in `reify`

- [#1256](https://github.com/paper-trail-gem/paper_trail/pull/1256) -
  Skip version for timestamp when changed attributed is ignored via Hash

### Dependencies

- Drop support for rails <= 5.1, which [reached EOL when 6.0 was released][2]
- Drop support for ruby 2.3 (reached EOL on 2019-04-01)

## 10.3.1 (2019-07-31)

### Breaking Changes

- None

### Added

- None

### Fixed

- None

### Dependencies

- [#1213](https://github.com/paper-trail-gem/paper_trail/pull/1213) - Allow
  contributors to install incompatible versions of ActiveRecord.
  See discussion in paper_trail/compatibility.rb

## 10.3.0 (2019-04-09)

### Breaking Changes

- None

### Added

- [#1194](https://github.com/paper-trail-gem/paper_trail/pull/1194) -
  Added a 'limit' option to has_paper_trail, allowing models to override the
  global `PaperTrail.config.version_limit` setting.

### Fixed

- [#1196](https://github.com/paper-trail-gem/paper_trail/pull/1196) -
  In the installation migration, change `versions.item_id` from 4 byte integer
  to 8 bytes (bigint).

## 10.2.1 (2019-03-14)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1184](https://github.com/paper-trail-gem/paper_trail/pull/1184) -
  No need to calculate previous values of skipped attributes
- [#1188](https://github.com/paper-trail-gem/paper_trail/pull/1188) -
  Optimized the memory allocations during the building of every particular
  Version object. That can help a lot for heavy bulk processing.
  In additional we advise to use `json[b]` DB types for `object`
  and `object_changes` Version columns, in order to reach best possible
  RAM performance.

## 10.2.0 (2019-01-31)

### Breaking Changes

- None

### Added

- Support ruby 2.6.0
- [#1182](https://github.com/paper-trail-gem/paper_trail/pull/1182) -
  Support rails 6.0.0.beta1

### Fixed

- [#1177](https://github.com/paper-trail-gem/paper_trail/pull/1177) -
  Do not store ignored and skipped attributes in `object_changes` on destroy.

### Deprecated

- [#1176](https://github.com/paper-trail-gem/paper_trail/pull/1176) -
  `config.paper_trail.enabled`

## 10.1.0 (2018-12-04)

### Breaking Changes

- None

### Deprecated

- [#1158](https://github.com/paper-trail-gem/paper_trail/pull/1158) - Passing
  association name as `versions:` option or Version class name as `class_name:`
  options directly to `has_paper_trail`. Use `has_paper_trail versions: {name:
  :my_name, class_name: "MyVersionModel"}` instead.

### Added

- [#1166](https://github.com/paper-trail-gem/paper_trail/pull/1166) -
  New global option `has_paper_trail_defaults`, defaults for `has_paper_trail`
- [#1158](https://github.com/paper-trail-gem/paper_trail/pull/1158) — Add the
  ability to pass options, such as `scope` or `extend:` to the `has_many
  :versions` association macro.
- [#1172](https://github.com/paper-trail-gem/paper_trail/pull/1172) -
  Support rails 6.0.0.alpha

### Fixed

- None

## 10.0.1 (2018-09-01)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1150](https://github.com/paper-trail-gem/paper_trail/pull/1150) - When PT-AT
  is not loaded, and someone sets `track_associations = false`, it should
  `warn`, not `raise`.

## 10.0.0 (2018-09-01)

PT 10 tackles some tough issues that required breaking changes. We fixed a
rare issue with STI, and saved major disk space in databases with tens
of millions of version records. Special thanks to @lorint and @seanlinsley,
respectively.

### Breaking changes affecting most people

- [#1132](https://github.com/paper-trail-gem/paper_trail/pull/1132) - Removed a
  dozen methods deprecated in PT 9. Make sure you've addressed all deprecation
  warnings before upgrading.

### Breaking changes affecting fewer people

- [db9c392d](https://github.com/paper-trail-gem/paper_trail/commit/db9c392d) -
  `paper_trail-association_tracking` is no longer a runtime dependency. If you
  use it (`track_associations = true`) you must now add it to your own `Gemfile`.
  See also [PT-AT #7](https://github.com/westonganger/paper_trail-association_tracking/issues/7)
- [#1130](https://github.com/paper-trail-gem/paper_trail/pull/1130) -
  Removed `save_changes`. For those wanting to save space, it's more effective
  to drop the `object` column. If you need ultimate control over the
  `object_changes` column, you can write your own `object_changes_adapter`.

### Breaking changes most people won't care about

- [#1121](https://github.com/paper-trail-gem/paper_trail/issues/1121) -
  `touch` now always inserts `null` in `object_changes`.
- [#1123](https://github.com/paper-trail-gem/paper_trail/pull/1123) -
  `object_changes` is now populated on destroy in order to make
  `where_object_changes` usable when you've dropped the `object` column.
  Sean is working on an optional backport migration and will post about it in
  [#1099](https://github.com/paper-trail-gem/paper_trail/issues/1099) when
  he's done.

### Added

- [#1099](https://github.com/paper-trail-gem/paper_trail/issues/1099) -
  Ability to save ~50% storage space by making the `object` column optional.
  Note that this disables `reify` and `where_object`.

### Fixed

- [#594](https://github.com/paper-trail-gem/paper_trail/issues/594) -
  A rare issue with reification of STI subclasses, affecting only PT-AT users
  who have a model with mutliple associations, whose foreign keys are named the
  same, and whose foreign models are STI with the same parent class. This fix
  requires a schema change. See [docs section 4.b.1 The optional `item_subtype`
  column](https://github.com/paper-trail-gem/paper_trail#4b-associations) for
  instructions.

## 9.2.0 (2018-06-09)

### Breaking Changes

- None

### Added

- [#1070](https://github.com/paper-trail-gem/paper_trail/issues/1070) -
  The experimental associations tracking feature has been moved to a separate
  gem, [paper_trail-association_tracking](https://github.com/westonganger/paper_trail-association_tracking). PT will,
  for now, have a runtime dependency on this new gem. So, assuming the gem
  extraction goes well, no breaking changes are anticipated.
- [#1093](https://github.com/paper-trail-gem/paper_trail/pull/1093) -
  `PaperTrail.config.object_changes_adapter` - Expert users can write their own
  adapter to control how the changes for each version are stored in the
  object_changes column. An example of this implementation using the hashdiff
  gem can be found here:
  [paper_trail-hashdiff](https://github.com/hashwin/paper_trail-hashdiff)

### Fixed

- None

## 9.1.1 (2018-05-30)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1098](https://github.com/paper-trail-gem/paper_trail/pull/1098) - Fix
  regression in 9.1.0 re: generator `--with-associations`

## 9.1.0 (2018-05-23)

### Breaking Changes

- None

### Added

- [#1091](https://github.com/paper-trail-gem/paper_trail/pull/1091) -
  `PaperTrail.config.association_reify_error_behaviour` - For users of the
  experimental association tracking feature. Starting with PT 9.0.0, reification
  of `has_one` associations is stricter. This option gives users some choices
  for how to handle the `PaperTrail::Reifiers::HasOne::FoundMoreThanOne` error
  introduced in PT 9. See README section 4.b.1. "Known Issues" for more details.

### Fixed

- None

## 9.0.2 (2018-05-14)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1084](https://github.com/paper-trail-gem/paper_trail/pull/1084)
  The `touch` callback (added in 9.0.0) now inserts the correct value into
  the `versions.object` column.

### Other

- Stop testing against rails 5.0, which reached EoL on 2018-04-15, when 5.2
  was released, per the [rails maintenance
  policy](http://guides.rubyonrails.org/maintenance_policy.html)

## 9.0.1 (2018-04-23)

### Breaking Changes

- None

### Added

- [#1076](https://github.com/paper-trail-gem/paper_trail/issues/1076)
  Add `save_with_version`, a replacement for deprecated method
  `touch_with_version`. Not exactly the same, it's a save, not a touch.
- [#1074](https://github.com/paper-trail-gem/paper_trail/pull/1074)
  `PaperTrail.request do ... end` now returns the value the given block.

### Fixed

- None

## 9.0.0 (2018-03-26)

### Breaking Changes, Major

- [#1063](https://github.com/paper-trail-gem/paper_trail/pull/1063) - `touch` will now
  create a version. This can be configured with the `:on` option. See
  documentation section 2.a. "Choosing Lifecycle Events To Monitor".
- Drop support for ruby 2.2, [whose EoL is the end of March,
  2018](https://www.ruby-lang.org/en/news/2017/09/14/ruby-2-2-8-released/)
- PaperTrail now uses `frozen_string_literal`, so you should assume that all
  strings it returns are frozen.
- Using `where_object_changes` to read YAML from a text column will now raise
  error, was deprecated in 8.1.0.

### Breaking Changes, Minor

- Removed deprecated `Version#originator`, use `#paper_trail_originator`
- Using paper_trail.on_destroy(:after) with ActiveRecord's
  belongs_to_required_by_default will produce an error instead of a warning.
- Removed the `warn_about_not_setting_whodunnit` controller method. This will
  only be a problem for you if you are skipping it, eg.
  `skip_after_action :warn_about_not_setting_whodunnit`, which few people did.

### Deprecated

- [#1063](https://github.com/paper-trail-gem/paper_trail/pull/1063) -
  `paper_trail.touch_with_version` is deprecated in favor of `touch`.
- [#1033](https://github.com/paper-trail-gem/paper_trail/pull/1033) - Request variables
  are now set using eg. `PaperTrail.request.whodunnit=` and the old way,
  `PaperTrail.whodunnit=` is deprecated.

### Added

- [#1067](https://github.com/paper-trail-gem/paper_trail/pull/1033) -
  Add support to Rails 5.2.
- [#1033](https://github.com/paper-trail-gem/paper_trail/pull/1033) -
  Set request variables temporarily using a block, eg.
  `PaperTrail.request(whodunnit: 'Jared') do .. end`
- [#1037](https://github.com/paper-trail-gem/paper_trail/pull/1037) Add `paper_trail.update_columns`
- [#961](https://github.com/paper-trail-gem/paper_trail/issues/961) - Instead of
  crashing when misconfigured Custom Version Classes are used, an error will be
  raised earlier, with a much more helpful message.
- Failing to set PaperTrail.config.track_associations will no longer produce
  a warning. The default (false) will remain the same.

### Fixed

- [#1051](https://github.com/paper-trail-gem/paper_trail/issues/1051) - `touch_with_version`
  should always create a version, regardles of the `:only` option
- [#1047](https://github.com/paper-trail-gem/paper_trail/issues/1047) - A rare issue
  where `touch_with_version` saved less data than expected, but only when the
  update callback was not installed, eg. `has_paper_trail(on: [])`
- [#1042](https://github.com/paper-trail-gem/paper_trail/issues/1042) - A rare issue
  with load order when using PT outside of rails
- [#594](https://github.com/paper-trail-gem/paper_trail/issues/594) - Improved the
  error message for a very rare issue in the experimental association tracking
  feature involving two has_one associations, referencing STI models with the
  same base class, and the same foreign_key.

## 8.1.2 (2017-12-22)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1028](https://github.com/paper-trail-gem/paper_trail/pull/1028) Reifying
  associations will now use `base_class` name instead of class name
  to reify STI models corrrectly.

## 8.1.1 (2017-12-10)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1018](https://github.com/paper-trail-gem/paper_trail/pull/1018)
  Serializing postgres arrays

## 8.1.0 (2017-11-30)

### Breaking Changes

- None

### Added

- [#997](https://github.com/paper-trail-gem/paper_trail/pull/997)
  Deprecate `where_object_changes` when reading YAML from a text column

### Fixed

- [#1009](https://github.com/paper-trail-gem/paper_trail/pull/1009)
  End generated `config/initializers/paper_trail.rb` with newline.

## 8.0.1 (2017-10-25)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#1003](https://github.com/paper-trail-gem/paper_trail/pull/1003) - Warn when PT
  cannot be loaded because rails is not loaded yet.

## 8.0.0 (2017-10-04)

### Breaking Changes

- Drop support for rails 4.0 and 4.1, whose EoL was
  [2016-06-30](http://weblog.rubyonrails.org/2016/6/30/Rails-5-0-final/)
- Drop support for ruby 2.1, whose EoL was [2017-04-01](http://bit.ly/2ppWDYa)
- [#803](https://github.com/paper-trail-gem/paper_trail/issues/803) -
  where_object_changes no longer supports reading json from a text column

### Added

- None

### Fixed

- [#996](https://github.com/paper-trail-gem/paper_trail/pull/996) - Incorrect
  item_type in association reification query

## 7.1.3 (2017-09-19)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#988](https://github.com/paper-trail-gem/paper_trail/pull/988) - Fix ActiveRecord
  version check in `VersionConcern` for Rails 4.0

## 7.1.2 (2017-08-30)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#985](https://github.com/paper-trail-gem/paper_trail/pull/985) - Fix RecordInvalid
  error on nil item association when belongs_to_required_by_default is enabled.
## 7.1.1 (2017-08-18)

### Breaking Changes

- None

### Added

- None

### Fixed

- Stop including unnecessary files in released gem. Reduces .gem file size
  from 100K to 30K.
- [#984](https://github.com/paper-trail-gem/paper_trail/pull/984) - Fix NameError
  suspected to be caused by autoload race condition.

## 7.1.0 (2017-07-09)

### Breaking Changes

- None

### Added

- [#803](https://github.com/paper-trail-gem/paper_trail/issues/803)
  Deprecate `where_object_changes` when reading json from a text column
- [#976](https://github.com/paper-trail-gem/paper_trail/pull/976)
  `PaperTrail.whodunnit` accepts a `Proc`

### Fixed

- None

## 7.0.3 (2017-06-01)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#959](https://github.com/paper-trail-gem/paper_trail/pull/959) -
  Add migration version (eg. `[5.1]`) to all migration generators.

## 7.0.2 (2017-04-26)

### Breaking Changes

- None

### Added

- [#932](https://github.com/paper-trail-gem/paper_trail/pull/932) -
  `PaperTrail.whodunnit` now accepts a block.

### Fixed

- [#956](https://github.com/paper-trail-gem/paper_trail/pull/956) -
  Fix ActiveRecord >= 5.1 version check

## 7.0.1 (2017-04-10)

### Breaking Changes

- None

### Added

- Generate cleaner migrations for databases other than MySQL

### Fixed

- [#949](https://github.com/paper-trail-gem/paper_trail/issues/949) - Inherit from the
  new versioned migration class, e.g. `ActiveRecord::Migration[5.1]`

## 7.0.0 (2017-04-01)

### Breaking Changes

- Drop support for ruby 1.9.3, whose EOL was 2015-02-23
- Drop support for ruby 2.0.0, whose EOL was 2016-02-24
- Remove deprecated config methods:
  - PaperTrail.serialized_attributes?
  - PaperTrail.config.serialized_attributes
  - PaperTrail.config.serialized_attributes=
- Sinatra integration moved to
  [paper_trail-sinatra](https://github.com/jaredbeck/paper_trail-sinatra) gem

### Added

- `PaperTrail.gem_version` returns a `Gem::Version`, nice for comparisons.

### Fixed

- [#925](https://github.com/paper-trail-gem/paper_trail/pull/925) - Update RSpec
  matchers to work with custom version association names
- [#929](https://github.com/paper-trail-gem/paper_trail/pull/929) -
  Fix error calling private method in rails 4.0
- [#938](https://github.com/paper-trail-gem/paper_trail/pull/938) - Fix bug where
  non-standard foreign key names broke belongs_to associations
- [#940](https://github.com/paper-trail-gem/paper_trail/pull/940) - When destroying
  versions to stay under version_limit, don't rely on the database to
  implicitly return the versions in the right order

## 6.0.2 (2016-12-13)

### Breaking Changes

- None

### Added

- None

### Fixed

- `88e513f` - Surprise argument modification bug in `where_object_changes`
- `c7efd62` - Column type-detection bug in `where_object_changes`
- [#905](https://github.com/paper-trail-gem/paper_trail/pull/905) - Only invoke
  `logger.warn` if `logger` instance exists

### Code Quality

- Improve Metrics/AbcSize from 30 to 22
- Improve Metrics/PerceivedComplexity from 10 to 9

## 6.0.1 (2016-12-04)

### Breaking Changes

- None

### Added

- None

### Fixed

- Remove rails 3 features that are no longer supported, most notably,
  `protected_attributes`.

## 6.0.0 (2016-12-03)

Now with rails 5.1 support, and less model pollution! About 40 methods that were
polluting your models' namespaces have been removed, reducing the chances of a
name conflict with your methods.

### Breaking Changes

- [#898](https://github.com/paper-trail-gem/paper_trail/pull/898) - Dropped support
  for rails 3
- [#864](https://github.com/paper-trail-gem/paper_trail/pull/864) - The model methods
  deprecated in 5.2.0 have been removed. Use `paper_trail.x` instead of `x`.
- [#861](https://github.com/paper-trail-gem/paper_trail/pull/861) - `timestamp_field=`
  removed without replacement. It is no longer configurable. The
  timestamp field in the `versions` table must now be named `created_at`.

### Deprecated

- None

### Added

- [#900](https://github.com/paper-trail-gem/paper_trail/pull/900/files) -
  Support for rails 5.1
- [#881](https://github.com/paper-trail-gem/paper_trail/pull/881) - Add RSpec matcher
  `have_a_version_with_changes` for easier testing.

### Fixed

- None

## 5.2.3 (2016-11-29)

### Breaking Changes

- None

### Deprecated

- None

### Added

- None

### Fixed

- [#889](https://github.com/paper-trail-gem/paper_trail/pull/889) -
  Fix warning message in instances when a version can't be persisted due to validation errors.
- [#868](https://github.com/paper-trail-gem/paper_trail/pull/868)
  Fix usage of find_by_id when primary key is not id, affecting reifying certain records.


## 5.2.2 (2016-09-08)

### Breaking Changes

- None

### Deprecated

- [#863](https://github.com/paper-trail-gem/paper_trail/pull/863) -
  PaperTrail.timestamp_field= deprecated without replacement.
  See [#861](https://github.com/paper-trail-gem/paper_trail/pull/861) for discussion.

### Added

- None

### Fixed

- None

## 5.2.1 (2016-09-02)

### Breaking Changes

- None

### Deprecated

- None

### Added

- None

### Fixed

- [#857](https://github.com/paper-trail-gem/paper_trail/pull/857) -
  Fix deserialization of enums written by PT 4.
- [#798](https://github.com/paper-trail-gem/paper_trail/issues/798) -
  Fix a rare bug with serialization of enums in rails 4.2 only when
  using `touch_with_version`.

## 5.2.0 (2016-06-27)

### Breaking Changes

- None

### Deprecated

- [#719](https://github.com/paper-trail-gem/paper_trail/pull/719) -
  The majority of model methods. Use paper_trail.x instead of x. Why? Your
  models are a crowded namespace, and we want to get out of your way!

### Added

- None

### Fixed

- None

## 5.1.1 (2016-05-31)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#813](https://github.com/paper-trail-gem/paper_trail/pull/813) -
  Warning for paper_trail_on_destroy(:after) for pre-releases of AR 5
- [#651](https://github.com/paper-trail-gem/paper_trail/issues/651) -
  Bug with installing PT on MySQL <= 5.6

## 5.1.0 (2016-05-20)

### Breaking Changes

- None

### Added

- [#809](https://github.com/paper-trail-gem/paper_trail/pull/809) -
  Print warning if version cannot be saved.

### Fixed

- [#812](https://github.com/paper-trail-gem/paper_trail/pull/812) -
  Issue with saving HABTM associated objects using accepts_nested_attributes_for
- [#811](https://github.com/paper-trail-gem/paper_trail/pull/811) -
  Avoid unnecessary query in #record_destroy
- Improvements to documentation

## 5.0.1 (2016-05-04)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#791](https://github.com/paper-trail-gem/paper_trail/issues/791) -
  A rare issue in applications that override `warn`.
- [#789](https://github.com/paper-trail-gem/paper_trail/issues/789) -
  A potentially common issue, in applications with initializers that use
  versioned models.

## 5.0.0 (2016-05-02)

### Breaking Changes

- [#758](https://github.com/paper-trail-gem/paper_trail/pull/758) -
  `PaperTrail.config.track_associations` getter method removed,
  use `track_associations?` instead.
- [#740](https://github.com/paper-trail-gem/paper_trail/issues/740) -
  `PaperTrail.config.track_associations?` now defaults to false
- [#723](https://github.com/paper-trail-gem/paper_trail/pull/723) -
  `PaperTrail.enabled=` now affects all threads
- [#556](https://github.com/paper-trail-gem/paper_trail/pull/556) /
  [#301](https://github.com/paper-trail-gem/paper_trail/issues/301) -
  If you are tracking who is responsible for changes with `whodunnit`, be aware
  that PaperTrail no longer adds the `set_paper_trail_whodunnit` before_action
  for you. Please add this before_action to your ApplicationController to
  continue recording whodunnit. See the readme for an example.
- [#683](https://github.com/paper-trail-gem/paper_trail/pull/683) /
  [#682](https://github.com/paper-trail-gem/paper_trail/issues/682) -
  Destroy callback default changed to :before to accommodate ActiveRecord 5
  option `belongs_to_required_by_default` and new Rails 5 default.

### Added

- [#771](https://github.com/paper-trail-gem/paper_trail/pull/771) -
  Added support for has_and_belongs_to_many associations
- [#741](https://github.com/paper-trail-gem/paper_trail/issues/741) /
  [#681](https://github.com/paper-trail-gem/paper_trail/pull/681)
  MySQL unicode support in migration generator
- [#689](https://github.com/paper-trail-gem/paper_trail/pull/689) -
  Rails 5 compatibility
- Added a rails config option: `config.paper_trail.enabled`
- [#503](https://github.com/paper-trail-gem/paper_trail/pull/730) -
  Support for reifying belongs_to associations.

### Fixed

- [#777](https://github.com/paper-trail-gem/paper_trail/issues/777) -
  Support HMT associations with `:source` option.
- [#738](https://github.com/paper-trail-gem/paper_trail/issues/738) -
  Rare bug where a non-versioned STI parent caused `changeset` to
  return an empty hash.
- [#731](https://github.com/paper-trail-gem/paper_trail/pull/731) -
  Map enums to database values before storing in `object_changes` column.
- [#715](https://github.com/paper-trail-gem/paper_trail/issues/715) -
  Optimize post-rollback association reset.
- [#701](https://github.com/paper-trail-gem/paper_trail/pull/701) /
  [#699](https://github.com/paper-trail-gem/paper_trail/issues/699) -
  Cleaning old versions explicitly preserves the most recent
  versions instead of relying on database result ordering.
- [#635](https://github.com/paper-trail-gem/paper_trail/issues/635) -
  A bug where it was not possible to disable PT when using a multi-threaded
  webserver.
- [#584](https://github.com/paper-trail-gem/paper_trail/issues/584) -
  Fixed deprecation warning for Active Record after_callback / after_commit

## 4.2.0 (2016-05-31)

### Breaking Changes

- None

### Added

- [#808](https://github.com/paper-trail-gem/paper_trail/pull/808) -
  Warn when destroy callback is set to :after with ActiveRecord 5
  option `belongs_to_required_by_default` set to `true`.

### Fixed

- None

## 4.1.0 (2016-01-30)

### Known Issues

- Version changesets now store ENUM values incorrectly (as nulls). Previously the values were stored as strings. This only affects Rails 4, not Rails 5. See [#926](https://github.com/paper-trail-gem/paper_trail/pull/926)

### Breaking Changes

- None

### Added

- A way to control the order of AR callbacks.
  [#614](https://github.com/paper-trail-gem/paper_trail/pull/614)
- Added `unversioned_attributes` option to `reify`.
  [#579](https://github.com/paper-trail-gem/paper_trail/pull/579)

### Fixed

- None

## 4.0.2 (2016-01-19)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#696](https://github.com/paper-trail-gem/paper_trail/issues/696) /
  [#697](https://github.com/paper-trail-gem/paper_trail/pull/697)
  Bind JSON query parameters in `where_object` and `where_object_changes`.

## 4.0.1 (2015-12-14)

### Breaking Changes

- None

### Added

- None

### Fixed

- [#636](https://github.com/paper-trail-gem/paper_trail/issues/636) -
  Should compile assets without a db connection
- [#589](https://github.com/paper-trail-gem/paper_trail/pull/589) /
  [#588](https://github.com/paper-trail-gem/paper_trail/issues/588) -
  Fixes timestamp for "create" versions

## 4.0.0 (2015-07-30)

This major release adds JSON column support in PostgreSQL, limited support for
versioning associations, various new configuration options, and a year's worth
of bug fixes. Thanks to everyone who helped test the two betas and two release
candidates.

### Breaking Changes

- Using a Rails initializer to reopen PaperTrail::Version or otherwise extend
  PaperTrail is no longer recommended. An alternative is described in the
  readme. See https://github.com/paper-trail-gem/paper_trail/pull/557 and
  https://github.com/paper-trail-gem/paper_trail/pull/492.
- If you depend on the `RSpec` or `Cucumber` helpers, you must
  [require them in your test helper](https://github.com/paper-trail-gem/paper_trail#testing).
- [#566](https://github.com/paper-trail-gem/paper_trail/pull/566) - Removed deprecated
  methods `paper_trail_on` and `paper_trail_off`. Use `paper_trail_on!` and
  `paper_trail_off!` instead.
- [#458](https://github.com/paper-trail-gem/paper_trail/pull/458) - Version metadata
  (the `:meta` option) from AR attributes for `create` events will now save the
  current value instead of `nil`.
- [#391](https://github.com/paper-trail-gem/paper_trail/issues/391) - `object_changes`
  value should dump to `YAML` as a normal `Hash` instead of an
  `ActiveSupport::HashWithIndifferentAccess`.
- [#375](https://github.com/paper-trail-gem/paper_trail/pull/375) /
  [#374](https://github.com/paper-trail-gem/paper_trail/issues/374) /
  [#354](https://github.com/paper-trail-gem/paper_trail/issues/354) /
  [#131](https://github.com/paper-trail-gem/paper_trail/issues/131) -
  Versions are now saved with an `after_` callback, instead of a `before_`
  callback. This ensures that the timestamp field for a version matches the
  corresponding timestamp in the model.
- `3da1f104` - `PaperTrail.config` and `PaperTrail.configure` are now
  identical: both return the `PaperTrail::Config` instance and also
  yield it if a block is provided.

### Added

- [#525](https://github.com/paper-trail-gem/paper_trail/issues/525) /
  [#512](https://github.com/paper-trail-gem/paper_trail/pull/512) -
  Support for virtual accessors and redefined setter and getter methods.
- [#518](https://github.com/paper-trail-gem/paper_trail/pull/518) - Support for
  querying against PostgreSQL's
  [`JSON` and `JSONB` column types](http://www.postgresql.org/docs/9.4/static/datatype-json.html)
  via `PaperTrail::VersionConcern#where_object` and
  `PaperTrail::VersionConcern#where_object_changes`
- [#507](https://github.com/paper-trail-gem/paper_trail/pull/507) -
  New option: `:save_changes` controls whether or not to save changes to the
  `object_changes` column (if it exists).
- [#500](https://github.com/paper-trail-gem/paper_trail/pull/500) - Support for
  passing an empty array to the `on` option (`on: []`) to disable all
  automatic versioning.
- [#494](https://github.com/paper-trail-gem/paper_trail/issues/494) - The install
  generator will warn the user if the migration they are attempting to
  generate already exists.
- [#484](https://github.com/paper-trail-gem/paper_trail/pull/484) - Support for
  [PostgreSQL's `JSONB` Type](http://www.postgresql.org/docs/9.4/static/datatype-json.html)
  for storing `object` and `object_changes`.
- [#439](https://github.com/paper-trail-gem/paper_trail/pull/439) /
  [#12](https://github.com/paper-trail-gem/paper_trail/issues/12) -
  Support for versioning associations (has many, has one, etc.) one level deep.
- [#420](https://github.com/paper-trail-gem/paper_trail/issues/420) - Add
  `VersionConcern#where_object_changes` instance method; acts as a helper for
  querying against the `object_changes` column in versions table.
- [#416](https://github.com/paper-trail-gem/paper_trail/issues/416) - Added a
  `config` option for enabling/disabling utilization of
  `serialized_attributes` for `ActiveRecord`, necessary because
  `serialized_attributes` has been deprecated in `ActiveRecord` version `4.2`
  and will be removed in version `5.0`
- [#399](https://github.com/paper-trail-gem/paper_trail/pull/399) - Add `:dup`
  argument for options hash to `reify` which forces a new model instance.
- [#394](https://github.com/paper-trail-gem/paper_trail/pull/394) - Add RSpec matcher
  `have_a_version_with` for easier testing.
- [#347](https://github.com/paper-trail-gem/paper_trail/pull/347) - Autoload
  `ActiveRecord` models in via a `Rails::Engine` when the gem is used with
  `Rails`.

### Fixed

- [#563](https://github.com/paper-trail-gem/paper_trail/pull/563) - Fixed a bug in
  `touch_with_version` so that it will still create a version even when the
  `on` option is, e.g. `[:create]`.
- [#541](https://github.com/paper-trail-gem/paper_trail/pull/541) -
  `PaperTrail.config.enabled` should be Thread Safe
- [#451](https://github.com/paper-trail-gem/paper_trail/issues/451) - Fix `reify`
  method in context of model where the base class has a default scope, and the
  live instance is not scoped within that default scope.
- [#440](https://github.com/paper-trail-gem/paper_trail/pull/440) - `versions`
  association should clear/reload after a transaction rollback.
- [#438](https://github.com/paper-trail-gem/paper_trail/issues/438) -
  `ModelKlass.paper_trail_enabled_for_model?` should return `false` if
  `has_paper_trail` has not been declared on the class.
- [#404](https://github.com/paper-trail-gem/paper_trail/issues/404) /
  [#428](https://github.com/paper-trail-gem/paper_trail/issues/428) -
  `model_instance.dup` does not need to be invoked when examining what the
  instance looked like before changes were persisted, which avoids issues if a
  3rd party has overriden the `dup` behavior. Also fixes errors occuring when
  a user attempts to update the inheritance column on an STI model instance in
  `ActiveRecord` 4.1.x
- [#427](https://github.com/paper-trail-gem/paper_trail/pull/427) - Fix `reify`
  method in context of model where a column has been removed.
- [#414](https://github.com/paper-trail-gem/paper_trail/issues/414) - Fix
  functionality `ignore` argument to `has_paper_trail` in `ActiveRecord` 4.
- [#413](https://github.com/paper-trail-gem/paper_trail/issues/413) - Utilize
  [RequestStore](https://github.com/steveklabnik/request_store) to ensure that
  the `PaperTrail.whodunnit` is set in a thread safe manner within Rails and
  Sinatra.
- [#381](https://github.com/paper-trail-gem/paper_trail/issues/381) - Fix `irb`
  warning: `can't alias context from irb_context`. `Rspec` and `Cucumber`
  helpers should not be loaded by default, regardless of whether those
  libraries are loaded.
- [#248](https://github.com/paper-trail-gem/paper_trail/issues/248) - In MySQL, to
  prevent truncation, generated migrations now use `longtext` instead of `text`.
- Methods handling serialized attributes should fallback to the currently set
  Serializer instead of always falling back to `PaperTrail::Serializers::YAML`.

### Deprecated

- [#479](https://github.com/paper-trail-gem/paper_trail/issues/479) - Deprecated
  `originator` method, use `paper_trail_originator`.

## 3.0.9

  - [#479](https://github.com/paper-trail-gem/paper_trail/issues/479) - Deprecated
    `originator` method in favor of `paper_trail_originator` Deprecation warning
    informs users that the `originator` of the methods will be removed in
    version `4.0`. (Backported from v4)
  - Updated deprecation warnings for `Model.paper_trail_on` and
    `Model.paper_trail_off` to have display correct version number the methods
    will be removed (`4.0`)

## 3.0.8

  - [#525](https://github.com/paper-trail-gem/paper_trail/issues/525) / [#512](https://github.com/paper-trail-gem/paper_trail/pull/512) -
    Support for virtual accessors and redefined setter and getter methods.

## 3.0.7

  - [#404](https://github.com/paper-trail-gem/paper_trail/issues/404) / [#428](https://github.com/paper-trail-gem/paper_trail/issues/428) -
    Fix errors occuring when a user attempts to update the inheritance column on an STI model instance in `ActiveRecord` 4.1.x

## 3.0.6

  - [#414](https://github.com/paper-trail-gem/paper_trail/issues/414) - Backport fix for `ignore` argument to `has_paper_trail` in
    `ActiveRecord` 4.

## 3.0.5

  - [#401](https://github.com/paper-trail-gem/paper_trail/issues/401) / [#406](https://github.com/paper-trail-gem/paper_trail/issues/406) -
    `PaperTrail::Version` class is not loaded via a `Rails::Engine`, even when the gem is used within Rails. This feature has
    will be re-introduced in version `4.0`.
  - [#398](https://github.com/paper-trail-gem/paper_trail/pull/398) - Only require the `RSpec` helper if `RSpec::Core` is required.

## 3.0.3
*This version was yanked from RubyGems and has been replaced by version `3.0.5`, which is almost identical, but does not eager load
in the `PaperTrail::Version` class through a `Rails::Engine` when the gem is used on Rails since it was causing issues for some users.*

  - [#386](https://github.com/paper-trail-gem/paper_trail/issues/386) - Fix eager loading of `versions` association with custom class name
    in `ActiveRecord` 4.1.
  - [#384](https://github.com/paper-trail-gem/paper_trail/issues/384) - Fix `VersionConcern#originator` instance method.
  - [#383](https://github.com/paper-trail-gem/paper_trail/pull/383) - Make gem compatible with `ActiveRecord::Enum` (available in `ActiveRecord` 4.1+).
  - [#380](https://github.com/paper-trail-gem/paper_trail/pull/380) / [#377](https://github.com/paper-trail-gem/paper_trail/issues/377) -
    Add `VersionConcern#where_object` instance method; acts as a helper for querying against the `object` column in versions table.
  - [#373](https://github.com/paper-trail-gem/paper_trail/pull/373) - Fix default sort order for the `versions` association in `ActiveRecord` 4.1.
  - [#372](https://github.com/paper-trail-gem/paper_trail/pull/372) - Use [Arel](https://github.com/rails/arel) for SQL construction.
  - [#365](https://github.com/paper-trail-gem/paper_trail/issues/365) - `VersionConcern#version_at` should return `nil` when receiving a timestamp
    that occured after the object was destroyed.
  - Expand `PaperTrail::VERSION` into a module, mimicking the form used by Rails to give it some additional modularity & versatility.
  - Fixed `VersionConcern#index` instance method so that it conforms to using the primary key for ordering when possible.

## 3.0.2

  - [#357](https://github.com/paper-trail-gem/paper_trail/issues/357) - If a `Version` instance is reified and then persisted at that state,
    it's timestamp attributes for update should still get `touch`ed.
  - [#351](https://github.com/paper-trail-gem/paper_trail/pull/351) / [#352](https://github.com/paper-trail-gem/paper_trail/pull/352) -
    `PaperTrail::Rails::Controller` should hook into all controller types, and should not get loaded unless `ActionController` is.
  - [#346](https://github.com/paper-trail-gem/paper_trail/pull/346) - `user_for_paper_trail` method should accommodate different types
    for return values from `current_user` method.
  - [#344](https://github.com/paper-trail-gem/paper_trail/pull/344) - Gem is now tested against `MySQL` and `PostgreSQL` in addition to `SQLite`.
  - [#317](https://github.com/paper-trail-gem/paper_trail/issues/317) / [#314](https://github.com/paper-trail-gem/paper_trail/issues/314) -
    `versions` should default to ordering via the primary key if it is an integer to avoid timestamp comparison issues.
  - `PaperTrail::Cleaner.clean_versions!` should group versions by `PaperTrail.timestamp_field` when deciding which ones to
    keep / destroy, instead of always grouping by the `created_at` field.
  - If a `Version` instance is reified and then persisted at that state, it's source version
    (`model_instance#version_association_name`, usually `model_instance#version`) will get cleared since persisting it causes it to
    become the live instance.
  - If `destroy` actions are tracked for a versioned model, invoking `destroy` on the model will cause the corresponding version that
    gets generated to be assigned as the source version (`model_instance#version_association_name`, usually `model_instance#version`).

## 3.0.1

  - [#340](https://github.com/paper-trail-gem/paper_trail/issues/340) - Prevent potential error encountered when using the `InstallGenerator`
    with Rails `4.1.0.rc1`.
  - [#334](https://github.com/paper-trail-gem/paper_trail/pull/334) - Add small-scope `whodunnit` method to `PaperTrail::Model::InstanceMethods`.
  - [#329](https://github.com/paper-trail-gem/paper_trail/issues/329) - Add `touch_with_version` method to `PaperTrail::Model::InstanceMethods`,
    to allow for generating a version while `touch`ing a model.
  - [#328](https://github.com/paper-trail-gem/paper_trail/pull/328) / [#326](https://github.com/paper-trail-gem/paper_trail/issues/326) /
    [#307](https://github.com/paper-trail-gem/paper_trail/issues/307) - `Model.paper_trail_enabled_for_model?` and
    `model_instance.without_versioning` is now thread-safe.
  - [#316](https://github.com/paper-trail-gem/paper_trail/issues/316) - `user_for_paper_trail` should default to `current_user.try(:id)`
    instead of `current_user` (if `current_user` is defined).
  - [#313](https://github.com/paper-trail-gem/paper_trail/pull/313) - Make the `Rails::Controller` helper compatible with
    `ActionController::API` for compatibility with the [`rails-api`](https://github.com/rails-api/rails-api) gem.
  - [#312](https://github.com/paper-trail-gem/paper_trail/issues/312) - Fix RSpec `with_versioning` class level helper method.
  - `model_instance.without_versioning` now yields the `model_instance`, enabling syntax like this:
    `model_instance.without_versioning { |obj| obj.update(:name => 'value') }`.
  - Deprecated `Model.paper_trail_on` and `Model.paper_trail_off` in favor of bang versions of the methods.
    Deprecation warning informs users that the non-bang versions of the methods will be removed in version `4.0`

## 3.0.0

  - [#305](https://github.com/paper-trail-gem/paper_trail/pull/305) - `PaperTrail::VERSION` should be loaded at runtime.
  - [#295](https://github.com/paper-trail-gem/paper_trail/issues/295) - Explicitly specify table name for version class when
    querying attributes. Prevents `AmbiguousColumn` errors on certain `JOIN` statements.
  - [#289](https://github.com/paper-trail-gem/paper_trail/pull/289) - Use `ActiveSupport::Concern` for implementation of base functionality on
    `PaperTrail::Version` class. Increases flexibility and makes it easier to use custom version classes with multiple `ActiveRecord` connections.
  - [#288](https://github.com/paper-trail-gem/paper_trail/issues/288) - Change all scope declarations to class methods on the `PaperTrail::Version`
    class. Fixes usability when `PaperTrail::Version.abstract_class? == true`.
  - [#287](https://github.com/paper-trail-gem/paper_trail/issues/287) - Support for
    [PostgreSQL's JSON Type](http://www.postgresql.org/docs/9.2/static/datatype-json.html) for storing `object` and `object_changes`.
  - [#281](https://github.com/paper-trail-gem/paper_trail/issues/281) - `Rails::Controller` helper will return `false` for the
    `paper_trail_enabled_for_controller` method if `PaperTrail.enabled? == false`.
  - [#280](https://github.com/paper-trail-gem/paper_trail/pull/280) - Don't track virtual timestamp attributes.
  - [#278](https://github.com/paper-trail-gem/paper_trail/issues/278) / [#272](https://github.com/paper-trail-gem/paper_trail/issues/272) -
    Make RSpec and Cucumber helpers usable with [Spork](https://github.com/sporkrb/spork) and [Zeus](https://github.com/burke/zeus).
  - [#273](https://github.com/paper-trail-gem/paper_trail/pull/273) - Make the `only` and `ignore` options accept `Hash` arguments;
    allows for conditional tracking.
  - [#264](https://github.com/paper-trail-gem/paper_trail/pull/264) - Allow unwrapped symbol to be passed in to the `on` option.
  - [#224](https://github.com/paper-trail-gem/paper_trail/issues/224)/[#236](https://github.com/paper-trail-gem/paper_trail/pull/236) -
    Fixed compatibility with [ActsAsTaggableOn](https://github.com/mbleigh/acts-as-taggable-on).
  - [#235](https://github.com/paper-trail-gem/paper_trail/pull/235) - Dropped unnecessary secondary sort on `versions` association.
  - [#216](https://github.com/paper-trail-gem/paper_trail/pull/216) - Added helper & extension for [RSpec](https://github.com/rspec/rspec),
    and helper for [Cucumber](http://cukes.info).
  - [#212](https://github.com/paper-trail-gem/paper_trail/pull/212) - Added `PaperTrail::Cleaner` module, useful for discarding draft versions.
  - [#207](https://github.com/paper-trail-gem/paper_trail/issues/207) - Versions for `'create'` events are now created with `create!` instead of
    `create` so that an exception gets raised if it is appropriate to do so.
  - [#199](https://github.com/paper-trail-gem/paper_trail/pull/199) - Rails 4 compatibility.
  - [#165](https://github.com/paper-trail-gem/paper_trail/pull/165) - Namespaced the `Version` class under the `PaperTrail` module.
  - [#119](https://github.com/paper-trail-gem/paper_trail/issues/119) - Support for [Sinatra](http://www.sinatrarb.com/); decoupled gem from `Rails`.
  - Renamed the default serializers from `PaperTrail::Serializers::Yaml` and `PaperTrail::Serializers::Json` to the capitalized forms,
    `PaperTrail::Serializers::YAML` and `PaperTrail::Serializers::JSON`.
  - Removed deprecated `set_whodunnit` method from Rails Controller scope.

## 2.7.2

  - [#228](https://github.com/paper-trail-gem/paper_trail/issues/228) - Refactored default `user_for_paper_trail` method implementation
    so that `current_user` only gets invoked if it is defined.
  - [#219](https://github.com/paper-trail-gem/paper_trail/pull/219) - Fixed issue where attributes stored with `nil` value might not get
    reified properly depending on the way the serializer worked.
  - [#213](https://github.com/paper-trail-gem/paper_trail/issues/213) - Added a `version_limit` option to the `PaperTrail::Config` options
    that can be used to restrict the number of versions PaperTrail will store per object instance.
  - [#187](https://github.com/paper-trail-gem/paper_trail/pull/187) - Confirmed JRuby support.
  - [#174](https://github.com/paper-trail-gem/paper_trail/pull/174) - The `event` field on the versions table can now be customized.

## 2.7.1

  - [#206](https://github.com/paper-trail-gem/paper_trail/issues/206) - Fixed Ruby 1.8.7 compatibility for tracking `object_changes`.
  - [#200](https://github.com/paper-trail-gem/paper_trail/issues/200) - Fixed `next_version` method so that it returns the live model
    when called on latest reified version of a model prior to the live model.
  - [#197](https://github.com/paper-trail-gem/paper_trail/issues/197) - PaperTrail now falls back on using YAML for serialization of
    serialized model attributes for storage in the `object` and `object_changes` columns in the `Version` table. This fixes
    compatibility for `Rails 3.0.x` for projects that employ the `serialize` declaration on a model.
  - [#194](https://github.com/paper-trail-gem/paper_trail/issues/194) - A JSON serializer is now included in the gem.
  - [#192](https://github.com/paper-trail-gem/paper_trail/pull/192) - `object_changes` should store serialized representation of serialized
    attributes for `create` actions (in addition to `update` actions, which had already been patched by
    [#180](https://github.com/paper-trail-gem/paper_trail/pull/180)).
  - [#190](https://github.com/paper-trail-gem/paper_trail/pull/190) - Fixed compatibility with
    [SerializedAttributes](https://github.com/technoweenie/serialized_attributes) gem.
  - [#189](https://github.com/paper-trail-gem/paper_trail/pull/189) - Provided support for a `configure` block initializer.
  - Added `setter` method for the `serializer` config option.

## 2.7.0

  - [#183](https://github.com/paper-trail-gem/paper_trail/pull/183) - Fully qualify the `Version` class to help prevent
    namespace resolution errors within other gems / plugins.
  - [#180](https://github.com/paper-trail-gem/paper_trail/pull/180) - Store serialized representation of serialized attributes
    on the `object` and `object_changes` columns in the `Version` table.
  - [#164](https://github.com/paper-trail-gem/paper_trail/pull/164) - Allow usage of custom serializer for storage of object attributes.

## 2.6.4

  - [#181](https://github.com/paper-trail-gem/paper_trail/issues/181)/[#182](https://github.com/paper-trail-gem/paper_trail/pull/182) -
    Controller metadata methods should only be evaluated when `paper_trail_enabled_for_controller == true`.
  - [#177](https://github.com/paper-trail-gem/paper_trail/issues/177)/[#178](https://github.com/paper-trail-gem/paper_trail/pull/178) -
    Factored out `version_key` into it's own method to prevent `ConnectionNotEstablished` error from getting thrown in
    instances where `has_paper_trail` is declared on class prior to ActiveRecord establishing a connection.
  - [#176](https://github.com/paper-trail-gem/paper_trail/pull/176) - Force metadata calls for attributes to use current value
    if attribute value is changing.
  - [#173](https://github.com/paper-trail-gem/paper_trail/pull/173) - Update link to [diff-lcs](https://github.com/halostatue/diff-lcs).
  - [#172](https://github.com/paper-trail-gem/paper_trail/pull/172) - Save `object_changes` on creation.
  - [#168](https://github.com/paper-trail-gem/paper_trail/pull/168) - Respect conditional `:if` or `:unless` arguments to the
    `has_paper_trail` method for `destroy` events.
  - [#167](https://github.com/paper-trail-gem/paper_trail/pull/167) - Fix `originator` method so that it works with subclasses and STI.
  - [#160](https://github.com/paper-trail-gem/paper_trail/pull/160) - Fixed failing tests and resolved out of date dependency issues.
  - [#157](https://github.com/paper-trail-gem/paper_trail/pull/157) - Refactored `class_attribute` names on the `ClassMethods` module
    for names that are not obviously pertaining to PaperTrail to prevent method name collision.

[1]: https://github.com/paper-trail-gem/paper_trail#4c-storing-metadata
[2]: https://guides.rubyonrails.org/maintenance_policy.html
[3]: https://www.ruby-lang.org/en/downloads/branches/
