module PaperTrail
  module RSpec
    module Helpers
      # Included in the RSpec configuration in `frameworks/rspec.rb`
      module InstanceMethods
        # enable versioning for specific blocks (at instance-level)
        def with_versioning(whodunnit: nil)
          was_whodunnit = ::PaperTrail.whodunnit
          was_enabled = ::PaperTrail.enabled?
          ::PaperTrail.whodunnit = whodunnit unless whodunnit.nil?
          ::PaperTrail.enabled = true
          yield
        ensure
          ::PaperTrail.enabled = was_enabled
          ::PaperTrail.whodunnit = was_whodunnit unless whodunnit.nil?
        end
      end

      # Extended by the RSpec configuration in `frameworks/rspec.rb`
      module ClassMethods
        # enable versioning for specific blocks (at class-level)
        def with_versioning(&block)
          context "with versioning", versioning: true do
            class_exec(&block)
          end
        end
      end
    end
  end
end
