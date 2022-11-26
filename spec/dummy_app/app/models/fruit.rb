# frozen_string_literal: true

# See also `Vegetable` which uses `JsonbVersion`.
class Fruit < ApplicationRecord
  if ENV["DB"] == "postgres"
    has_paper_trail versions: { class_name: "JsonVersion" }
  end
end
