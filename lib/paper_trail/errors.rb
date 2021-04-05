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
end
