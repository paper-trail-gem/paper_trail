# frozen_string_literal: true

require "request_store"

module PaperTrail
  # Manages variables that affect the current HTTP request, such as `whodunnit`.
  module Request
    class << self
      # @api private
      def clear_transaction_id
        self.transaction_id = nil
      end

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

      # Sets whether PaperTrail is enabled or disabled for the current request.
      # @api public
      def enabled_for_controller=(value)
        store[:request_enabled_for_controller] = value
      end

      # Returns `true` if PaperTrail is enabled for the request, `false` otherwise.
      #
      # See `PaperTrail::Rails::Controller#paper_trail_enabled_for_controller`.
      # @api public
      def enabled_for_controller?
        !!store[:request_enabled_for_controller]
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
        !!store.fetch(:"enabled_for_#{model}", true)
      end

      # @api private
      def set(options)
        options.each do |k, v|
          store[k] = v
        end
      end

      # Returns a deep copy of the internal hash from our RequestStore.
      # Keys are all symbols. Values are mostly primitives, but
      # whodunnit can be a Proc.
      # @api private
      def to_h
        store.store.deep_dup
      end

      # @api private
      def transaction_id
        store[:transaction_id]
      end

      # @api public
      def transaction_id=(id)
        store[:transaction_id] = id
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

      # Thread-safe hash to hold PaperTrail's data. Initializing with needed
      # default values.
      # @api private
      def store
        RequestStore.store[:paper_trail] ||= {
          request_enabled_for_controller: true
        }
      end
    end
  end
end
