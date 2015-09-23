class BeforeDestroyModifier < CallbackModifier
  has_paper_trail :on => []
  paper_trail_on_destroy :before
end

class AfterDestroyModifier < CallbackModifier
  has_paper_trail :on => []
  paper_trail_on_destroy :after
end

class NoArgDestroyModifier < CallbackModifier
  has_paper_trail :on => []
  paper_trail_on_destroy
end

class UpdateModifier < CallbackModifier
  paper_trail_on_update
end

class CreateModifier < CallbackModifier
  paper_trail_on_create
end

class DefaultModifier < CallbackModifier
  # Because of the way I set up the destroy method for testing
  # has_paper_trail has to be initialized in this model seperately
  has_paper_trail
end
