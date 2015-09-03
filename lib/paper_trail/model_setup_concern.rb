require 'active_support/concern'


module PaperTrail
  module ModelSetupConcern
    extend ::ActiveSupport::Concern

    def setup_model_for_paper_trail(options = {})
      # Lazily include the instance methods so we don't clutter up
      # any more ActiveRecord models than we have to.
      send :include, PaperTrail::Model::InstanceMethods

      class_attribute :version_association_name
      self.version_association_name = options[:version] || :version

      # The version this instance was reified from.
      attr_accessor self.version_association_name

      class_attribute :version_class_name
      self.version_class_name = options[:class_name] || 'PaperTrail::Version'

      class_attribute :paper_trail_options
      self.paper_trail_options = options.dup

      [:ignore, :skip, :only].each do |k|
        paper_trail_options[k] =
          [paper_trail_options[k]].flatten.compact.map { |attr| attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s }
      end

      paper_trail_options[:meta] ||= {}
      paper_trail_options[:save_changes] = true if paper_trail_options[:save_changes].nil?

      class_attribute :versions_association_name
      self.versions_association_name = options[:versions] || :versions

      attr_accessor :paper_trail_event

      # `has_many` syntax for specifying order uses a lambda in Rails 4
      if ::ActiveRecord::VERSION::MAJOR >= 4
        has_many self.versions_association_name,
          lambda { order(model.timestamp_sort_order) },
          :class_name => self.version_class_name, :as => :item
      else
        has_many self.versions_association_name,
          :class_name => self.version_class_name,
          :as         => :item,
          :order      => self.paper_trail_version_class.timestamp_sort_order
      end

      # Reset the transaction id when the transaction is closed.
      after_commit :reset_transaction_id
      after_rollback :reset_transaction_id
      after_rollback :clear_rolled_back_versions
    end
  end
end