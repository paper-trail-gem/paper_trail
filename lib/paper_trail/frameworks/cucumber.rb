# frozen_string_literal: true

# before hook for Cucumber
Before do
  PaperTrail.enabled = false
  PaperTrail.request.enabled = true
  PaperTrail.request.whodunnit = nil
  PaperTrail.request.controller_info = {} if defined?(::Rails)
end

module PaperTrail
  module Cucumber
    # Helper method for enabling PT in Cucumber features.
    module Extensions
      # :call-seq:
      # with_versioning
      #
      # enable versioning for specific blocks

      def with_versioning
        was_enabled = ::PaperTrail.enabled?
        ::PaperTrail.enabled = true
        begin
          yield
        ensure
          ::PaperTrail.enabled = was_enabled
        end
      end
    end
  end
end

World PaperTrail::Cucumber::Extensions
