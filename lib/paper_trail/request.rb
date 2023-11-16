# frozen_string_literal: true

require "paper_trail/request/current_attributes"

module PaperTrail
  # Manages variables that affect the current HTTP request, such as `whodunnit`.
  #
  # Please do not use `PaperTrail::Request` directly, use `PaperTrail.request`.
  # Currently, `Request` is a `Module`, but in the future it is quite possible
  # we may make it a `Class`. If we make such a choice, we will not provide any
  # warning and will not treat it as a breaking change. You've been warned :)
  #
  # @api private
  module Request
    class << self
      # Sets any data from the controller that you want PaperTrail to store.
      # See also `PaperTrail::Rails::Controller#info_for_paper_trail`.
      #
      #   PaperTrail.request.controller_info = { ip: request_user_ip }
      #   PaperTrail.request.controller_info # => { ip: '127.0.0.1' }
      #
      # @api public
      delegate :controller_info=, to: :current_attributes

      # Returns the data from the controller that you want PaperTrail to store.
      # See also `PaperTrail::Rails::Controller#info_for_paper_trail`.
      #
      #   PaperTrail.request.controller_info = { ip: request_user_ip }
      #   PaperTrail.request.controller_info # => { ip: '127.0.0.1' }
      #
      # @api public
      delegate :controller_info, to: :current_attributes

      # Switches PaperTrail off for the given model.
      # @api public
      def disable_model(model_class)
        enabled_for_model(model_class, false)
      end

      # Switches PaperTrail on for the given model.
      # @api public
      def enable_model(model_class)
        enabled_for_model(model_class, true)
      end

      # Sets whether PaperTrail is enabled or disabled for the current request.
      # @api public
      delegate :enabled=, to: :current_attributes

      # Returns `true` if PaperTrail is enabled for the request, `false` otherwise.
      # See `PaperTrail::Rails::Controller#paper_trail_enabled_for_controller`.
      # @api public
      def enabled?
        !!current_attributes.enabled
      end

      # Sets whether PaperTrail is enabled or disabled for this model in the
      # current request.
      # @api public
      def enabled_for_model(model, value)
        current_attributes.enabled_for[model] = value
      end

      # Returns `true` if PaperTrail is enabled for this model in the current
      # request, `false` otherwise.
      # @api public
      def enabled_for_model?(model)
        model.include?(::PaperTrail::Model::InstanceMethods) &&
          !!(current_attributes.enabled_for[model] ||
            current_attributes.enabled_for[model].nil?)
      end

      # Temporarily set `options` and execute a block.
      # @api private
      def with(options, &block)
        validate_public_options!(options)
        transform_public_options!(options)
        current_attributes.set(options, &block)
      end

      # Sets who is responsible for any changes that occur during request. You
      # would normally use this in a migration or on the console, when working
      # with models directly.
      #
      # `value` is usually a string, the name of a person, but you can set
      # anything that responds to `to_s`. You can also set a Proc, which will
      # not be evaluated until `whodunnit` is called later, usually right before
      # inserting a `Version` record.
      #
      # @api public
      delegate :whodunnit=, to: :current_attributes

      # Returns who is responsible for any changes that occur during request.
      #
      # @api public
      def whodunnit
        who = current_attributes.whodunnit
        who.respond_to?(:call) ? who.call : who
      end

      private

      # Returns the current request attributes with default values initialized if necessary.
      # @api private
      def current_attributes
        CurrentAttributes.tap do |attrs|
          attrs.enabled = true if attrs.enabled.nil?
        end
      end

      # Returns a deep copy of the current attributes. Keys are
      # all symbols. Values are mostly primitives, but whodunnit can be a Proc.
      # We cannot use Marshal.dump here because it doesn't support Proc. It is
      # unclear exactly how `deep_dup` handles a Proc, but it doesn't complain.
      # @api private
      def to_h
        current_attributes.attributes.except(:skip_reset).deep_dup
      end

      # Provide a helpful error message if someone has a typo in one of their
      # option keys. We don't validate option values here. That's traditionally
      # been handled with casting (`to_s`, `!!`) in the accessor method.
      # @api private
      def validate_public_options!(options)
        options.keys.each do |key|
          case key
          when :enabled,
               /^enabled_for_/,
               :controller_info,
               :whodunnit
            next
          else
            raise InvalidOption, "Invalid option: #{key}"
          end
        end
      end

      # Transform public options into internal attributes.
      # @api private
      def transform_public_options!(options)
        options[:enabled_for] = current_attributes.enabled_for.deep_dup
        options.keys.grep(/^enabled_for_/).each do |key|
          model_klass = key.to_s.sub("enabled_for_", "").constantize
          options[:enabled_for][model_klass] = options.delete(key)
        end
      end
    end
  end
end
