module PaperTrail
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end


    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.  Each version of
      # the model is available in the `versions` association.
      #
      # Options:
      # :class_name   the name of a custom Version class.  This class should inherit from Version.
      # :ignore       an array of attributes for which a new `Version` will not be created if only they change.
      # :only         inverse of `ignore` - a new `Version` will be created only for these attributes if supplied
      # :meta         a hash of extra data to store.  You must add a column to the `versions` table for each key.
      #               Values are objects or procs (which are called with `self`, i.e. the model with the paper
      #               trail).  See `PaperTrail::Controller.info_for_paper_trail` for how to store data from
      #               the controller.
      def has_paper_trail(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        # The version this instance was reified from.
        attr_accessor :version

        cattr_accessor :version_class_name
        self.version_class_name = options[:class_name] || 'Version'

        cattr_accessor :ignore
        self.ignore = ([options[:ignore]].flatten.compact || []).map &:to_s

        cattr_accessor :only
        self.only = ([options[:only]].flatten.compact || []).map &:to_s

        cattr_accessor :meta
        self.meta = options[:meta] || {}

        cattr_accessor :paper_trail_enabled_for_model
        self.paper_trail_enabled_for_model = true

        has_many :versions, :class_name => version_class_name, :as => :item, :order => "created_at ASC, #{self.primary_key} ASC"

        after_create  :record_create
        before_update :record_update
        after_destroy :record_destroy
      end

      # Switches PaperTrail off for this class.
      def paper_trail_off
        self.paper_trail_enabled_for_model = false
      end

      # Switches PaperTrail on for this class.
      def paper_trail_on
        self.paper_trail_enabled_for_model = true
      end
    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_paper_trail`.
    module InstanceMethods
      # Returns true if this instance is the current, live one;
      # returns false if this instance came from a previous version.
      def live?
        version.nil?
      end

      # Returns who put the object into its current state.
      def originator
        version_class.with_item_keys(self.class.name, id).last.try :whodunnit
      end

      # Returns the object (not a Version) as it was at the given timestamp.
      def version_at(timestamp, reify_options={})
        # Because a version stores how its object looked *before* the change,
        # we need to look for the first version created *after* the timestamp.
        version = versions.after(timestamp).first
        version ? version.reify(reify_options) : self
      end

      # Returns the object (not a Version) as it was most recently.
      def previous_version
        preceding_version = version ? version.previous : versions.last
        preceding_version.try :reify
      end

      # Returns the object (not a Version) as it became next.
      def next_version
        # NOTE: if self (the item) was not reified from a version, i.e. it is the
        # "live" item, we return nil.  Perhaps we should return self instead?
        subsequent_version = version ? version.next : nil
        subsequent_version.reify if subsequent_version
      end

      private

      def version_class
        version_class_name.constantize
      end

      def record_create
        if switched_on?
          versions.create merge_metadata(:event => 'create', :whodunnit => PaperTrail.whodunnit)
        end
      end

      def record_update
        if switched_on? && changed_notably?
          versions.build merge_metadata(:event     => 'update',
                                        :object    => object_to_string(item_before_change),
                                        :whodunnit => PaperTrail.whodunnit)
        end
      end

      def record_destroy
        if switched_on? and not new_record?
          version_class.create merge_metadata(:item_id   => self.id,
                                              :item_type => self.class.name,
                                              :event     => 'destroy',
                                              :object    => object_to_string(item_before_change),
                                              :whodunnit => PaperTrail.whodunnit)
        end
        versions.send :load_target
      end

      def merge_metadata(data)
        # First we merge the model-level metadata in `meta`.
        meta.each do |k,v|
          data[k] =
            if v.respond_to?(:call)
              v.call(self)
            elsif v.is_a?(Symbol) && respond_to?(v)
              send(v)
            else
              v
            end
        end
        # Second we merge any extra data from the controller (if available).
        data.merge(PaperTrail.controller_info || {})
      end

      def item_before_change
        previous = self.dup
        # `dup` clears timestamps so we add them back.
        all_timestamp_attributes.each do |column|
          previous[column] = send(column) if respond_to?(column) && !send(column).nil?
        end
        previous.tap do |prev|
          prev.id = id
          changed_attributes.each { |attr, before| prev[attr] = before }
        end
      end

      def object_to_string(object)
        object.attributes.to_yaml
      end

      def changed_notably?
        notably_changed.any?
      end

      def notably_changed
        self.class.only.empty? ? changed_and_not_ignored : (changed_and_not_ignored & self.class.only)
      end

      def changed_and_not_ignored
        changed - self.class.ignore
      end

      def switched_on?
        PaperTrail.enabled? && PaperTrail.enabled_for_controller? && self.class.paper_trail_enabled_for_model
      end
    end

  end
end
