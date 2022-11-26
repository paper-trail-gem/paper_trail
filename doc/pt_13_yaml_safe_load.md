# PT 13 uses YAML.safe_load

Starting with 13.0.0, in Rails >= 7.0, PT's default serializer
(`PaperTrail::Serializers::YAML`) will use `safe_load` unless
`ActiveRecord.use_yaml_unsafe_load`.

PT 14.0.0 extends this protection to Rails 6.

Earlier versions of PT use `unsafe_load`.

## Motivation

> A few days ago Rails released versions 7.0.3.1, 6.1.6.1, 6.0.5.1, and 5.2.8.1.
> These are security updates that impact applications that use serialised
> attributes on Active Record models. These updates, identified by CVE-2022-32224
> cover a possible escalation to RCE when using YAML serialised columns in Active
> Record.
> https://rubyonrails.org/2022/7/15/this-week-in-rails-rails-security-releases-improved-generator-option-handling-and-more-24774592

## Who is affected by this change?

This change only affects users whose `versions` table has `object` or
`object_changes` columns of type `text`, and who use the YAML serializer. People
who use the JSON serializer, or those with `json(b)` columns, are unaffected.

## To continue using the YAML serializer

We recommend switching to `json(b)` columns, or at least JSON in a `text` column
(see "Other serializers" below). If you must continue using the YAML serializer,
PT users are required to configure `ActiveRecord.yaml_column_permitted_classes`
correctly for their own application. Users may want to start with the following
safe-list:

```ruby
::ActiveRecord.use_yaml_unsafe_load = false
::ActiveRecord.yaml_column_permitted_classes = [
  ::ActiveRecord::Type::Time::Value,
  ::ActiveSupport::TimeWithZone,
  ::ActiveSupport::TimeZone,
  ::BigDecimal,
  ::Date,
  ::Symbol,
  ::Time
]
```

## Other serializers

While YAML remains the default serializer in PT for historical compatibility,
we have recommended JSON instead, for years. See:

- [PostgreSQL JSON column type support](https://github.com/paper-trail-gem/paper_trail/blob/v12.3.0/README.md#postgresql-json-column-type-support)
- [Convert existing YAML data to JSON](https://github.com/paper-trail-gem/paper_trail/blob/v12.3.0/README.md#convert-existing-yaml-data-to-json)
