# frozen_string_literal: true

require "securerandom"

class CustomIdKeyRecord < ActiveRecord::Base
  has_paper_trail id_key: :uuid, versions: { class_name: "CustomPrimaryKeyRecordVersion" }

  before_create do
    self.uuid ||= SecureRandom.uuid
  end
end
