# frozen_string_literal: true

# See also `SecretAgent` which uses `JsonVersion`.
class SecretAgentB < ApplicationRecord
  try :encrypts, :name

  has_paper_trail versions: {
    class_name: ENV["DB"] == "postgres" ? "JsonbVersion" : "PaperTrail::Version"
  }
end
