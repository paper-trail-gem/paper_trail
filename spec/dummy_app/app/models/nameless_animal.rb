# frozen_string_literal: true

class NamelessAnimal < Animal
  self.ignored_columns += ["name"]
end
