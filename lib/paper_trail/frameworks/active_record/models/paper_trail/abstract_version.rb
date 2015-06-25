require 'paper_trail/version_concern'

module PaperTrail
  # When using PaperTrail with multiple tables without STI
  # PaperTrail::Versions needs to be abstract or you have to create
  # an unused versions table since Rails now reloads gemfiles as well
  # as application code and the preferred method was to use an initializer
  # which isn't reloaded resulting in PaperTrail::Version not being abstract.
  #
  # For details see #488 and #483
  #
  # So if you want an abstract base class and not use sti use AbstractVersion as
  # your parent class.
  class AbstractVersion < ::ActiveRecord::Base
    include PaperTrail::VersionConcern
    self.abstract_class = true
  end
end
