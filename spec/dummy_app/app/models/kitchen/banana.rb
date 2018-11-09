# frozen_string_literal: true

module Kitchen
  class Banana < ActiveRecord::Base
    has_paper_trail versions: { class_name: "Kitchen::BananaVersion" }
  end
end
