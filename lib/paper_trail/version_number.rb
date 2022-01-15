# frozen_string_literal: true

module PaperTrail
  # The version number of the paper_trail gem. Not to be confused with
  # `PaperTrail::Version`. Ruby constants are case-sensitive, apparently,
  # and they are two different modules! It would be nice to remove `VERSION`,
  # because of this confusion, but it's not worth the breaking change.
  # People are encouraged to use `PaperTrail.gem_version` instead.
  module VERSION
    MAJOR = 13
    MINOR = 0
    TINY = 0

    # Set PRE to nil unless it's a pre-release (beta, rc, etc.)
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
