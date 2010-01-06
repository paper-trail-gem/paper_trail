module PaperTrail

  def self.included(base)
    base.send :extend, ClassMethods
  end


  module ClassMethods
    # Options:
    # :ignore    an array of attributes for which a new +Version+ will not be created if only they change.
    # :meta      a hash of extra data to store.  You must add a column to the versions table for each key.
    #            Values are objects or procs (which are called with +self+, i.e. the model with the paper
    #            trail).
    def has_paper_trail(options = {})
      send :include, InstanceMethods

      cattr_accessor :ignore
      self.ignore = (options[:ignore] || []).map &:to_s

      cattr_accessor :meta
      self.meta = options[:meta] || {}
      
      cattr_accessor :paper_trail_active
      self.paper_trail_active = true

      has_many :versions, :as => :item, :order => 'created_at ASC, id ASC'

      after_create  :record_create
      before_update :record_update
      after_destroy :record_destroy
    end

    def paper_trail_off
      self.paper_trail_active = false
    end

    def paper_trail_on
      self.paper_trail_active = true
    end
  end


  module InstanceMethods
    def record_create
      if self.class.paper_trail_active
        versions.create merge_metadata(:event => 'create', :whodunnit => PaperTrail.whodunnit)
      end
    end

    def record_update
      if changed_and_we_care? and self.class.paper_trail_active
        versions.build merge_metadata(:event     => 'update',
                                      :object    => object_to_string(previous_version),
                                      :whodunnit => PaperTrail.whodunnit)
      end
    end

    def record_destroy
      if self.class.paper_trail_active
        versions.create merge_metadata(:event     => 'destroy',
                                       :object    => object_to_string(previous_version),
                                       :whodunnit => PaperTrail.whodunnit)
      end
    end

    private

    def merge_metadata(data)
      meta.each do |k,v|
        data[k] = v.respond_to?(:call) ? v.call(self) : v
      end
      data
    end

    def previous_version
      previous = self.clone
      previous.id = id
      changes.each do |attr, ary|
        previous.send "#{attr}=", ary.first
      end
      previous
    end

    def object_to_string(object)
      object.attributes.to_yaml
    end

    def changed_and_we_care?
      changed? and !(changed - self.class.ignore).empty?
    end
  end

end

ActiveRecord::Base.send :include, PaperTrail
