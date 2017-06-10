class CallbackModifier < ActiveRecord::Base
  has_paper_trail on: []

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

class BeforeDestroyModifier < CallbackModifier
  has_paper_trail on: []
  paper_trail.on_destroy :before
end

class AfterDestroyModifier < CallbackModifier
  has_paper_trail on: []
  paper_trail.on_destroy :after
end

class NoArgDestroyModifier < CallbackModifier
  has_paper_trail on: []
  paper_trail.on_destroy
end

class UpdateModifier < CallbackModifier
  has_paper_trail on: []
  paper_trail.on_update
end

class CreateModifier < CallbackModifier
  has_paper_trail on: []
  paper_trail.on_create
end

class DefaultModifier < CallbackModifier
  has_paper_trail
end
