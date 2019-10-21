# frozen_string_literal: true

require "securerandom"

module PaperTrailCustomId
  module ModelConfig
    def primary_key_for_has_many_versions
      instance_variable_get(:@model_class).paper_trail_options[:id_key] ||
        super
    end
  end
end

module PaperTrail
  class ModelConfig
    prepend ::PaperTrailCustomId::ModelConfig
  end
end

class CustomIdKeyRecord < ActiveRecord::Base
  has_paper_trail id_key: :uuid, versions: { class_name: "CustomPrimaryKeyRecordVersion" }

  before_create do
    self.uuid ||= SecureRandom.uuid
  end
end
