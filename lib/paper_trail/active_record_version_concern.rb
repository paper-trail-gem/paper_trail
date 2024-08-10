# frozen_string_literal: true

# Is used to handle the deprecation warning in the different versions of ActiveRecord.
module ActiveRecordVersionConcern
  module_function

  def deprecation
    if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("7.2")
      ::ActiveSupport::Deprecation
    else
      ::ActiveSupport::Deprecation._instance
    end
  end
end
