# frozen_string_literal: true

module PaperTrail
  # Rails does not follow SemVer, makes breaking changes in minor versions.
  # Breaking changes are expected, and are generally good for the rails
  # ecosystem. However, they often require dozens of hours to fix, even with the
  # [help of experts](https://github.com/paper-trail-gem/paper_trail/pull/899).
  #
  # It is not safe to assume that a new version of rails will be compatible with
  # PaperTrail. PT is only compatible with the versions of rails that it is
  # tested against. See `.github/workflows/test.yml`.
  #
  # However, as of
  # [#1213](https://github.com/paper-trail-gem/paper_trail/pull/1213) our
  # gemspec allows installation with newer, incompatible rails versions. We hope
  # this will make it easier for contributors to work on compatibility with
  # newer rails versions. Most PT users should avoid incompatible rails
  # versions.
  module Compatibility
    ACTIVERECORD_GTE = ">= 6.1" # enforced in gemspec
    ACTIVERECORD_LT = "< 7.3" # not enforced in gemspec

    E_INCOMPATIBLE_AR = <<-EOS
      PaperTrail %s is not compatible with ActiveRecord %s. We allow PT
      contributors to install incompatible versions of ActiveRecord, and this
      warning can be silenced with an environment variable, but this is a bad
      idea for normal use. Please install a compatible version of ActiveRecord
      instead (%s). Please see the discussion in paper_trail/compatibility.rb
      for details.
    EOS

    # Normal users need a warning if they accidentally install an incompatible
    # version of ActiveRecord. Contributors can silence this warning with an
    # environment variable.
    def self.check_activerecord(ar_version)
      raise ::TypeError unless ar_version.instance_of?(::Gem::Version)
      return if ::ENV["PT_SILENCE_AR_COMPAT_WARNING"].present?
      req = ::Gem::Requirement.new([ACTIVERECORD_GTE, ACTIVERECORD_LT])
      unless req.satisfied_by?(ar_version)
        ::Kernel.warn(
          format(
            E_INCOMPATIBLE_AR,
            ::PaperTrail.gem_version,
            ar_version,
            req
          )
        )
      end
    end
  end
end
