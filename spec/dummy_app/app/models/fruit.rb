# frozen_string_literal: true

# See also `Vegetable` which uses `JsonbVersion`.
class Fruit < ApplicationRecord
  if ENV["DB"] == "postgres"
    has_paper_trail versions: { class_name: "JsonVersion" }
  end

  if PaperTrail.active_record_gte_7_0?
    encrypts :supplier
  end
end
