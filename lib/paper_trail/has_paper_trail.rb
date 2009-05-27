module PaperTrail

  def self.included(base)
    base.send :extend, ClassMethods
  end


  module ClassMethods
    def has_paper_trail
      send :include, InstanceMethods
      
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
      versions.create(:event     => 'create',
                      :whodunnit => PaperTrail.whodunnit) if self.class.paper_trail_active
    end

    def record_update
      if changed? and self.class.paper_trail_active
        versions.build :event     => 'update',
                       :object    => object_to_string(previous_version),
                       :whodunnit => PaperTrail.whodunnit
      end
    end

    def record_destroy
      versions.create(:event     => 'destroy',
                      :object    => object_to_string(previous_version),
                      :whodunnit => PaperTrail.whodunnit) if self.class.paper_trail_active
    end

    private

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
  end

end

ActiveRecord::Base.send :include, PaperTrail
