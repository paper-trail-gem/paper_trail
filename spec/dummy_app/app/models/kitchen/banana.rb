# frozen_string_literal: true

module Kitchen
  class Banana < ApplicationRecord
    has_paper_trail versions: { class_name: "Kitchen::BananaVersion" }
  end
end
