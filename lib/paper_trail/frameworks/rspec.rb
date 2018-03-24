# frozen_string_literal: true

require "rspec/core"
require "rspec/matchers"
require "paper_trail/frameworks/rspec/helpers"

RSpec.configure do |config|
  config.include ::PaperTrail::RSpec::Helpers::InstanceMethods
  config.extend ::PaperTrail::RSpec::Helpers::ClassMethods

  config.before(:each) do
    ::PaperTrail.enabled = false
    ::PaperTrail.request.enabled = true
    ::PaperTrail.request.whodunnit = nil
    ::PaperTrail.request.controller_info = {} if defined?(::Rails) && defined?(::RSpec::Rails)
  end

  config.before(:each, versioning: true) do
    ::PaperTrail.enabled = true
  end
end

RSpec::Matchers.define :be_versioned do
  # check to see if the model has `has_paper_trail` declared on it
  match { |actual| actual.is_a?(::PaperTrail::Model::InstanceMethods) }
end

RSpec::Matchers.define :have_a_version_with do |attributes|
  # check if the model has a version with the specified attributes
  match do |actual|
    versions_association = actual.class.versions_association_name
    actual.send(versions_association).where_object(attributes).any?
  end
end

RSpec::Matchers.define :have_a_version_with_changes do |attributes|
  # check if the model has a version changes with the specified attributes
  match do |actual|
    versions_association = actual.class.versions_association_name
    actual.send(versions_association).where_object_changes(attributes).any?
  end
end
