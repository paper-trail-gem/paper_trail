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

if ActiveRecord.gem_version < Gem::Version.new("5") ||
    !ActiveRecord::Base.belongs_to_required_by_default

  class AfterDestroyModifier < CallbackModifier
    has_paper_trail on: []
    paper_trail.on_destroy :after
  end

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
