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
      # :on           the events to track (optional; defaults to all of them).  Set to an array of
      #               `:create`, `:update`, `:destroy` as desired.
      # :class_name   the name of a custom Version class.  This class should inherit from Version.
      # :ignore       an array of attributes for which a new `Version` will not be created if only they change.
      # :if, :unless  Procs that allow to specify conditions when to save versions for an object
      # :only         inverse of `ignore` - a new `Version` will be created only for these attributes if supplied
      # :skip         fields to ignore completely.  As with `ignore`, updates to these fields will not create
      #               a new `Version`.  In addition, these fields will not be included in the serialized versions
      #               of the object whenever a new `Version` is created.
      # :meta         a hash of extra data to store.  You must add a column to the `versions` table for each key.
      #               Values are objects or procs (which are called with `self`, i.e. the model with the paper
      #               trail).  See `PaperTrail::Controller.info_for_paper_trail` for how to store data from
      #               the controller.
      # :versions     the name to use for the versions association.  Default is `:versions`.
      # :version      the name to use for the method which returns the version the instance was reified from.
      #               Default is `:version`.
      def has_paper_trail(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        class_attribute :version_association_name
        self.version_association_name = options[:version] || :version

        # The version this instance was reified from.
        attr_accessor self.version_association_name

        class_attribute :version_class_name
        self.version_class_name = options[:class_name] || '::Version'

        class_attribute :paper_trail_options
        self.paper_trail_options = options.dup

        [:ignore, :skip, :only].each do |k|
          paper_trail_options[k] =
            ([paper_trail_options[k]].flatten.compact || []).map &:to_s
        end

        paper_trail_options[:meta] ||= {}

        class_attribute :paper_trail_enabled_for_model
        self.paper_trail_enabled_for_model = true

        class_attribute :versions_association_name
        self.versions_association_name = options[:versions] || :versions

        attr_accessor :paper_trail_event

        has_many self.versions_association_name,
                 :class_name => version_class_name,
                 :as         => :item,
                 :order      => "#{PaperTrail.timestamp_field} ASC, #{self.version_key} ASC"

        after_create  :record_create, :if => :save_version? if !options[:on] || options[:on].include?(:create)
        before_update :record_update, :if => :save_version? if !options[:on] || options[:on].include?(:update)
        after_destroy :record_destroy, :if => :save_version? if !options[:on] || options[:on].include?(:destroy)
      end

      def version_key
        self.version_class_name.constantize.primary_key
      end

      # Switches PaperTrail off for this class.
      def paper_trail_off
        self.paper_trail_enabled_for_model = false
      end

      # Switches PaperTrail on for this class.
      def paper_trail_on
        self.paper_trail_enabled_for_model = true
      end

      # Used for Version#object attribute
      def serialize_attributes_for_paper_trail(attributes)
        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            coder = PaperTrail::Serializers::Yaml unless coder.respond_to?(:dump) # Fall back to YAML if `coder` has no `dump` method
            attributes[key] = coder.dump(attributes[key])
          end
        end
      end

      def unserialize_attributes_for_paper_trail(attributes)
        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            coder = PaperTrail::Serializers::Yaml unless coder.respond_to?(:dump)
            attributes[key] = coder.load(attributes[key])
          end
        end
      end

      # Used for Version#object_changes attribute
      def serialize_attribute_changes(changes)
        serialized_attributes.each do |key, coder|
          if changes.key?(key)
            coder = PaperTrail::Serializers::Yaml unless coder.respond_to?(:dump) # Fall back to YAML if `coder` has no `dump` method
            old_value, new_value = changes[key]
            changes[key] = [coder.dump(old_value),
                            coder.dump(new_value)]
          end
        end
      end

      def unserialize_attribute_changes(changes)
        serialized_attributes.each do |key, coder|
          if changes.key?(key)
            coder = PaperTrail::Serializers::Yaml unless coder.respond_to?(:dump)
            old_value, new_value = changes[key]
            changes[key] = [coder.load(old_value),
                            coder.load(new_value)]
          end
        end
      end
    end

    # Wrap the following methods in a module so we can include them only in the
    # ActiveRecord models that declare `has_paper_trail`.
    module InstanceMethods
      # Returns true if this instance is the current, live one;
      # returns false if this instance came from a previous version.
      def live?
        source_version.nil?
      end

      # Returns who put the object into its current state.
      def originator
        version_class.with_item_keys(self.class.base_class.name, id).last.try :whodunnit
      end

      # Returns the object (not a Version) as it was at the given timestamp.
      def version_at(timestamp, reify_options={})
        # Because a version stores how its object looked *before* the change,
        # we need to look for the first version created *after* the timestamp.
        v = send(self.class.versions_association_name).following(timestamp).first
        v ? v.reify(reify_options) : self
      end

      # Returns the objects (not Versions) as they were between the given times.
      def versions_between(start_time, end_time, reify_options={})
        versions = send(self.class.versions_association_name).between(start_time, end_time)
        versions.collect { |version| version_at(version.send PaperTrail.timestamp_field) }
      end

      # Returns the object (not a Version) as it was most recently.
      def previous_version
        preceding_version = source_version ? source_version.previous : send(self.class.versions_association_name).last
        preceding_version.reify if preceding_version
      end

      # Returns the object (not a Version) as it became next.
      # NOTE: if self (the item) was not reified from a version, i.e. it is the
      #  "live" item, we return nil.  Perhaps we should return self instead?
      def next_version
        subsequent_version = source_version.next
        subsequent_version ? subsequent_version.reify : self.class.find(self.id)
      rescue
        nil
      end

      # Executes the given method or block without creating a new version.
      def without_versioning(method = nil)
        paper_trail_was_enabled = self.paper_trail_enabled_for_model
        self.class.paper_trail_off
        method ? method.to_proc.call(self) : yield
      ensure
        self.class.paper_trail_on if paper_trail_was_enabled
      end

      private

      def version_class
        version_class_name.constantize
      end

      def source_version
        send self.class.version_association_name
      end

      def record_create
        if switched_on?
          data = {
            :event     => paper_trail_event || 'create',
            :whodunnit => PaperTrail.whodunnit
          }

          if changed_notably? and version_class.column_names.include?('object_changes')
            data[:object_changes] = PaperTrail.serializer.dump(changes_for_paper_trail)
          end

          send(self.class.versions_association_name).create merge_metadata(data)
        end
      end

      def record_update
        if switched_on? && changed_notably?
          data = {
            :event     => paper_trail_event || 'update',
            :object    => object_to_string(item_before_change),
            :whodunnit => PaperTrail.whodunnit
          }
          if version_class.column_names.include? 'object_changes'
            data[:object_changes] = PaperTrail.serializer.dump(changes_for_paper_trail)
          end
          send(self.class.versions_association_name).build merge_metadata(data)
        end
      end

      def changes_for_paper_trail
        self.changes.delete_if do |key, value|
          !notably_changed.include?(key)
        end.tap do |changes|
          self.class.serialize_attribute_changes(changes) # Use serialized value for attributes when necessary
        end
      end

      def record_destroy
        if switched_on? and not new_record?
          version_class.create merge_metadata(:item_id   => self.id,
                                              :item_type => self.class.base_class.name,
                                              :event     => paper_trail_event || 'destroy',
                                              :object    => object_to_string(item_before_change),
                                              :whodunnit => PaperTrail.whodunnit)
        end
        send(self.class.versions_association_name).send :load_target
      end

      def merge_metadata(data)
        # First we merge the model-level metadata in `meta`.
        paper_trail_options[:meta].each do |k,v|
          data[k] =
            if v.respond_to?(:call)
              v.call(self)
            elsif v.is_a?(Symbol) && respond_to?(v)
              # if it is an attribute that is changing, be sure to grab the current version
              if has_attribute?(v) && send("#{v}_changed?".to_sym)
                send("#{v}_was".to_sym)
              else
                send(v)
              end
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
        _attrs = object.attributes.except(*self.class.paper_trail_options[:skip]).tap do |attributes|
          self.class.serialize_attributes_for_paper_trail attributes
        end
        PaperTrail.serializer.dump(_attrs)
      end

      def changed_notably?
        notably_changed.any?
      end

      def notably_changed
        only = self.class.paper_trail_options[:only]
        only.empty? ? changed_and_not_ignored : (changed_and_not_ignored & only)
      end

      def changed_and_not_ignored
        ignore = self.class.paper_trail_options[:ignore]
        skip   = self.class.paper_trail_options[:skip]
        changed - ignore - skip
      end

      def switched_on?
        PaperTrail.enabled? && PaperTrail.enabled_for_controller? && self.class.paper_trail_enabled_for_model
      end

      def save_version?
        if_condition     = self.class.paper_trail_options[:if]
        unless_condition = self.class.paper_trail_options[:unless]
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end
