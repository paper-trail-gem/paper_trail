# frozen_string_literal: true

# See also `Fruit` which uses `JsonVersion`.
class Vegetable < ApplicationRecord
  has_paper_trail versions: {
    class_name: ENV["DB"] == "postgres" ? "JsonbVersion" : "PaperTrail::Version"
  }, on: %i[create update]
end
