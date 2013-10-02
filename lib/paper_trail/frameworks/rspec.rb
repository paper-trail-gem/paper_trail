require 'rspec/core'
require 'rspec/matchers'
require File.expand_path('../rspec/extensions', __FILE__)

RSpec.configure do |config|
  config.include ::PaperTrail::RSpec::Extensions

  config.before(:each) do
    ::PaperTrail.enabled = false
    ::PaperTrail.whodunnit = nil
    ::PaperTrail.controller_info = {} if defined?(::Rails) && defined?(::RSpec::Rails)
  end

  config.before(:each, :versioning => true) do
    ::PaperTrail.enabled = true
  end
end

RSpec::Matchers.define :be_versioned do
  # check to see if the model has `has_paper_trail` declared on it
  match { |actual| actual.kind_of?(::PaperTrail::Model::InstanceMethods) }
end
