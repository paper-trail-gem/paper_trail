require 'paper_trail/rspec/paper_trail_extensions'

module RSpec
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'paper_trail.rspec_extensions' do
        RSpec.configure do |config|
          config.include RSpec::PaperTrailExtensions

          config.before(:each) do
            ::PaperTrail.enabled = false
            ::PaperTrail.controller_info = {}
            ::PaperTrail.whodunnit = nil
          end

          config.before(:each, versioning: true) do
            ::PaperTrail.enabled = true
          end
        end

        RSpec::Matchers.define :be_versioned do
          match do |actual|
            actual.respond_to?(:versions)
          end
        end
      end
    end
  end
end
