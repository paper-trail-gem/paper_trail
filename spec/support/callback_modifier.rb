class BeforeDestroyModifier < CallbackModifier
  paper_trail_before_destroy
end

class AfterDestroyModifier < CallbackModifier
  paper_trail_after_destroy
end

class NoArgDestroyModifier < CallbackModifier
  paper_trail_destroy
end

class UpdateModifier < CallbackModifier
  paper_trail_update
end

class CreateModifier < CallbackModifier
  paper_trail_create
end

class DefaultModifier < CallbackModifier
  has_paper_trail
end
