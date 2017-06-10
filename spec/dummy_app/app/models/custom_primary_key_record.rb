require "securerandom"

class CustomPrimaryKeyRecord < ActiveRecord::Base
  self.primary_key = :uuid

  has_paper_trail class_name: "CustomPrimaryKeyRecordVersion"

  # This default_scope is to test the case of the Version#item association
  # not returning the item due to unmatched default_scope on the model.
  default_scope { where(name: "custom_primary_key_record") }

  before_create do
    self.uuid ||= SecureRandom.uuid
  end
end
