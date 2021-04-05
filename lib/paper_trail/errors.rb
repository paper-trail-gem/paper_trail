# frozen_string_literal: true

module PaperTrail
  # Generic PaperTrail exception.
  # @api public
  class Error < StandardError
  end

  # An unexpected option, perhaps a typo, was passed to a public API method.
  # @api public
  class InvalidOption < Error
  end

  # The application's database schema is not supported.
  # @api public
  class UnsupportedSchema < Error
  end

  # The application's database column type is not supported.
  # @api public
  class UnsupportedColumnType < UnsupportedSchema
    def initialize(method:, expected:, actual:)
      super(
        format(
          "%s expected %s column, got %s",
          method,
          expected,
          actual
        )
      )
    end
  end
end
