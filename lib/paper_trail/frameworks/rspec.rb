if defined?(RSpec)
  require File.expand_path('../rspec/extensions', __FILE__)

  RSpec.configure do |config|
    config.include ::PaperTrail::RSpec::Extensions

    config.before(:each) do
      ::PaperTrail.enabled = false
      ::PaperTrail.whodunnit = nil
    end

    config.before(:each, versioning: true) do
      ::PaperTrail.enabled = true
    end
  end

  RSpec::Matchers.define :be_versioned do
    # check to see if the model has `has_paper_trail` declared on it
    match { |actual| actual.kind_of?(::PaperTrail::Model::InstanceMethods) }
  end

  # The `Rails` helper also sets the `controller_info` config variable in a `before_filter`...
  if defined?(::Rails) && defined?(RSpec::Rails)
    module RSpec
      module Rails
        class Railtie < ::Rails::Railtie
          initializer 'paper_trail.rspec_extensions' do
            RSpec.configure do |config|
              config.before(:each) { ::PaperTrail.controller_info = {} }
            end
          end
        end
      end
    end
  end

end
