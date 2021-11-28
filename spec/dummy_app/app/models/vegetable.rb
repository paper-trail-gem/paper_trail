# frozen_string_literal: true

# See also `Fruit` which uses `JsonVersion`.
class Vegetable < ActiveRecord::Base
  if ENV["DB"] == "postgres"
    has_paper_trail versions: { class_name: "JsonbVersion" }
  end
end
