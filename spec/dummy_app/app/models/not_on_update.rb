# frozen_string_literal: true

# This model does not record versions when updated.
class NotOnUpdate < ApplicationRecord
  has_paper_trail on: %i[create destroy]
end
