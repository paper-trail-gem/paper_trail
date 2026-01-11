# frozen_string_literal: true

module PaperTrail
  # Provides functionality to temporarily bypass ActiveRecord's readonly attribute checks
  # in a thread-safe manner.
  #
  # When `raise_on_assign_to_attr_readonly` is set to true in ActiveRecord configuration,
  # setting a value to an attribute marked as `attr_readonly` will raise an exception.
  # see. https://github.com/rails/rails/blob/86eb00986e1b5030f8b1d67d61f080800f1ae5a0/activerecord/lib/active_record/readonly_attributes.rb
  #
  # This module allows temporarily bypassing this check by making _attr_readonly return
  # an empty array for specific threads while preserving the original behavior for other threads.
  #
  # @api private
  module AttributeReadonlyBypass
    # Instance variable name to track if bypass module has been installed
    BYPASS_INSTALLED_IVAR = :@paper_trail_readonly_bypass_installed

    # Thread-local variable key for storing bypass list
    THREAD_BYPASS_KEY = :paper_trail_bypass_readonly

    class << self
      # Temporarily bypass readonly attribute check for the current thread
      #
      # @param model [ActiveRecord::Base] The model instance to bypass readonly checks for
      # @yield The block to execute with readonly checks bypassed
      # @return The result of the yielded block
      def with_bypass!(model)
        return yield unless model.class.respond_to?(:_attr_readonly)

        enable_bypass(model.class)
        add_to_thread_bypass_list(model.class)

        yield
      ensure
        remove_from_thread_bypass_list(model.class)
      end

      private

      # Enable readonly bypass by prepending EmptyReadonlyAttributes module
      def enable_bypass(klass)
        return if klass.instance_variable_get(BYPASS_INSTALLED_IVAR)

        klass.singleton_class.prepend(EmptyReadonlyAttributes)
        klass.instance_variable_set(BYPASS_INSTALLED_IVAR, true)
      end

      # Add model class to thread-local bypass list
      def add_to_thread_bypass_list(klass)
        Thread.current[THREAD_BYPASS_KEY] ||= Set.new
        Thread.current[THREAD_BYPASS_KEY] << klass
      end

      # Remove model class from thread-local bypass list
      def remove_from_thread_bypass_list(klass)
        Thread.current[THREAD_BYPASS_KEY]&.delete(klass)
      end
    end

    # Module that overrides _attr_readonly to return an empty array for bypassing threads
    # while preserving the original value for other threads.
    # This module is prepended to the singleton class to override the class method.
    module EmptyReadonlyAttributes
      def _attr_readonly
        if bypassed?
          []
        else
          super
        end
      end

      private

      # Check if current thread should bypass readonly check
      def bypassed?
        Thread.current[AttributeReadonlyBypass::THREAD_BYPASS_KEY]&.include?(self)
      end
    end
  end
end
