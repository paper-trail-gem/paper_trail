module PaperTrail
  module RSpec
    module Helpers
      module InstanceMethods
        # enable versioning for specific blocks (at instance-level)
        def with_versioning
          was_enabled = ::PaperTrail.enabled?
          ::PaperTrail.enabled = true
          yield
        ensure
          ::PaperTrail.enabled = was_enabled
        end
      end

      module ClassMethods
        # enable versioning for specific blocks (at class-level)
        def with_versioning(&block)
          context 'with versioning', :versioning => true do
            class_exec(&block)
          end
        end
      end
    end
  end
end
