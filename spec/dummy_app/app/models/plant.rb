# frozen_string_literal: true

class Plant < ApplicationRecord
  has_paper_trail
  self.inheritance_column = "species"

  class << self
    # Rails 6.1 adds a public method to overwrite sti finder methods. In earlier versions, users
    # may use the private method find_sti_class.
    #
    # See https://github.com/rails/rails/pull/37500
    if method_defined?(:sti_class_for)
      def sti_class_for(type_name)
        super(type_name.camelize)
      end
    else
      def find_sti_class(type_name)
        super(type_name.camelize)
      end
    end
  end
end
