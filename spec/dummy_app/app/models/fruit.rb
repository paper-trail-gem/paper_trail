# frozen_string_literal: true

class Fruit < ActiveRecord::Base
  if ENV["DB"] == "postgres" || JsonVersion.table_exists?
    has_paper_trail versions: { class_name: "JsonVersion" }
  end
end
