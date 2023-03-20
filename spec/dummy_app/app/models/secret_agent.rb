# frozen_string_literal: true

# See also `SecretAgentB` which uses `JsonbVersion`.
class SecretAgent < ApplicationRecord
  try :encrypts, :name

  has_paper_trail versions: {
    class_name: ENV["DB"] == "postgres" ? "JsonVersion" : "PaperTrail::Version"
  }
end
