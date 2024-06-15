# frozen_string_literal: true

module CallbackModifier
  extend ActiveSupport::Concern

  included do
    self.table_name = "callback_modifiers"
  end

  def test_destroy
    transaction do
      run_callbacks(:destroy) do
        self.deleted = true
        save!
      end
    end
  end

  def flagged_deleted?
    deleted?
  end
end

class BeforeDestroyModifier < ApplicationRecord
  include CallbackModifier

  has_paper_trail on: []
  paper_trail.on_destroy :before
end

unless ActiveRecord::Base.belongs_to_required_by_default
  class AfterDestroyModifier < ApplicationRecord
    include CallbackModifier

    has_paper_trail on: []
    paper_trail.on_destroy :after
  end
end

class NoArgDestroyModifier < ApplicationRecord
  include CallbackModifier

  has_paper_trail on: []
  paper_trail.on_destroy
end

class UpdateModifier < ApplicationRecord
  include CallbackModifier

  has_paper_trail on: []
  paper_trail.on_update
end

class CreateModifier < ApplicationRecord
  include CallbackModifier

  has_paper_trail on: []
  paper_trail.on_create
end

class DefaultModifier < ApplicationRecord
  include CallbackModifier

  has_paper_trail
end
