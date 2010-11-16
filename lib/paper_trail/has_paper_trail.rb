module PaperTrail
  module Model

    def self.included(base)
      base.send :extend, ClassMethods

      # The version this instance was reified from.
      attr_accessor :version
    end


    module ClassMethods
      # Declare this in your model to track every create, update, and destroy.  Each version of
      # the model is available in the `versions` association.
      #
      # Options:
      # :ignore    an array of attributes for which a new `Version` will not be created if only they change.
      # :meta      a hash of extra data to store.  You must add a column to the `versions` table for each key.
      #            Values are objects or procs (which are called with `self`, i.e. the model with the paper
      #            trail).  See `PaperTrail::Controller.info_for_paper_trail` for how to store data from
      #            the controller.
      def has_paper_trail(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        cattr_accessor :ignore
        self.ignore = (options[:ignore] || []).map &:to_s

        cattr_accessor :meta
        self.meta = options[:meta] || {}

        # Indicates whether or not PaperTrail is active for this class.
        # This is independent of whether PaperTrail is globally enabled or disabled.
        cattr_accessor :paper_trail_active
        self.paper_trail_active = true

        has_many :versions, :as => :item, :order => 'created_at ASC, id ASC'

        after_create  :record_create
        before_update :record_update
        after_destroy :record_destroy
      end

      # Switches PaperTrail off for this class.
      def paper_trail_off
        self.paper_trail_active = false
      end

      # Switches PaperTrail on for this class.
      def paper_trail_on
        self.paper_trail_active = true
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
        versions.last.try :whodunnit
      end

      # Returns the object (not a Version) as it was at the given timestamp.
      def version_at(timestamp)
        # Because a version stores how its object looked *before* the change,
        # we need to look for the first version created *after* the timestamp.
        version = versions.first :conditions => ['created_at > ?', timestamp], :order => 'created_at ASC, id ASC'
        version ? version.reify : self
      end

      # Returns the object (not a Version) as it was most recently.
      def previous_version
        last_version = version ? version.previous : versions.last
        last_version.try :reify
      end

      # Returns the object (not a Version) as it became next.
      def next_version
        # NOTE: if self (the item) was not reified from a version, i.e. it is the
        # "live" item, we return nil.  Perhaps we should return self instead?
        subsequent_version = version ? version.next : nil
        subsequent_version.reify if subsequent_version
      end

      private

      def record_create
        if switched_on?
          versions.create merge_metadata(:event => 'create', :whodunnit => PaperTrail.whodunnit)
        end
      end

      def record_update
        if switched_on? && changed_and_we_care?
          versions.build merge_metadata(:event     => 'update',
                                        :object    => object_to_string(item_before_change),
                                        :whodunnit => PaperTrail.whodunnit)
        end
      end

      def record_destroy
        if switched_on? and not new_record?
          Version.create merge_metadata(:item      => self,
                                        :event     => 'destroy',
                                        :object    => object_to_string(item_before_change),
                                        :whodunnit => PaperTrail.whodunnit)
        end
      end

      def merge_metadata(data)
        # First we merge the model-level metadata in `meta`.
        meta.each do |k,v|
          data[k] = v.respond_to?(:call) ? v.call(self) : v
        end
        # Second we merge any extra data from the controller (if available).
        data.merge(PaperTrail.controller_info || {})
      end

      def item_before_change
        previous = self.clone
        previous.id = id
        changes.each do |attr, ary|
          previous.send :write_attribute, attr.to_sym, ary.first
        end
        previous
      end

      def object_to_string(object)
        object.attributes.to_yaml
      end

      def changed_and_we_care?
        changed? and !(changed - self.class.ignore).empty?
      end

      # Returns `true` if PaperTrail is globally enabled and active for this class,
      # `false` otherwise.
      def switched_on?
        PaperTrail.enabled? && self.class.paper_trail_active
      end
    end

  end
end

ActiveRecord::Base.send :include, PaperTrail::Model
