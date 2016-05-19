Attribute Serializers
=====================

"Serialization" here refers to the preparation of data for insertion into a
database, particularly the `object` and `object_changes` columns in the
`versions` table.

Likewise, "deserialization" refers to any processing of data after they
have been read from the database, for example preparing the result of
`VersionConcern#changeset`.
