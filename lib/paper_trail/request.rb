# frozen_string_literal: true

require "request_store"

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
      def controller_info=(value)
        store[:controller_info] = value
      end

      # Returns the data from the controller that you want PaperTrail to store.
      # See also `PaperTrail::Rails::Controller#info_for_paper_trail`.
      #
      #   PaperTrail.request.controller_info = { ip: request_user_ip }
      #   PaperTrail.request.controller_info # => { ip: '127.0.0.1' }
      #
      # @api public
      def controller_info
        store[:controller_info]
      end

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
      def enabled=(value)
        store[:enabled] = value
      end

      # Returns `true` if PaperTrail is enabled for the request, `false` otherwise.
      # See `PaperTrail::Rails::Controller#paper_trail_enabled_for_controller`.
      # @api public
      def enabled?
        !!store[:enabled]
      end

      # Sets whether PaperTrail is enabled or disabled for this model in the
      # current request.
      # @api public
      def enabled_for_model(model, value)
        store[:"enabled_for_#{model}"] = value
      end

      # Returns `true` if PaperTrail is enabled for this model in the current
      # request, `false` otherwise.
      # @api public
      def enabled_for_model?(model)
        model.include?(::PaperTrail::Model::InstanceMethods) &&
          !!store.fetch(:"enabled_for_#{model}", true)
      end

      # @api private
      def merge(options)
        options.to_h.each do |k, v|
          store[k] = v
        end
      end

      # @api private
      def set(options)
        store.clear
        merge(options)
      end

      # Returns a deep copy of the internal hash from our RequestStore. Keys are
      # all symbols. Values are mostly primitives, but whodunnit can be a Proc.
      # We cannot use Marshal.dump here because it doesn't support Proc. It is
      # unclear exactly how `deep_dup` handles a Proc, but it doesn't complain.
      # @api private
      def to_h
        store.deep_dup
      end

      # Temporarily set `options` and execute a block.
      # @api private
      def with(options)
        return unless block_given?
        validate_public_options(options)
        before = to_h
        merge(options)
        yield
      ensure
        set(before)
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
      def whodunnit=(value)
        store[:whodunnit] = value
      end

      # Returns who is reponsible for any changes that occur during request.
      #
      # @api public
      def whodunnit
        who = store[:whodunnit]
        who.respond_to?(:call) ? who.call : who
      end

      private

      # Returns a Hash, initializing with default values if necessary.
      # @api private
      def store
        RequestStore.store[:paper_trail] ||= {
          enabled: true
        }
      end

      # Provide a helpful error message if someone has a typo in one of their
      # option keys. We don't validate option values here. That's traditionally
      # been handled with casting (`to_s`, `!!`) in the accessor method.
      # @api private
      def validate_public_options(options)
        options.each do |k, _v|
          case k
          when :controller_info,
              /enabled_for_/,
              :enabled,
              :whodunnit
            next
          else
            raise InvalidOption, "Invalid option: #{k}"
          end
        end
      end
    end
  end
end
