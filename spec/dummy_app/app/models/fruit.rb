# frozen_string_literal: true

class Fruit < ActiveRecord::Base
  if PaperTrail::TestEnv.json? || JsonVersion.table_exists?
    has_paper_trail versions: { class_name: "JsonVersion" }
  end
end
