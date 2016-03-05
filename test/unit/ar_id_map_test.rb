require "test_helper"

class ARIdMapTest < ActiveSupport::TestCase
  setup do
    @widget = Widget.new
    @widget.update_attributes name: "Henry", created_at: Time.now - 1.day
    @widget.update_attributes name: "Harry"
  end

  if defined?(ActiveRecord::IdentityMap) && ActiveRecord::IdentityMap.respond_to?(:without)
    should "not clobber the IdentityMap when reifying" do
      module ActiveRecord::IdentityMap
        class << self
          alias __without without
          def without(&block)
            @unclobbered = true
            __without(&block)
          end
        end
      end

      @widget.versions.last.reify
      assert ActiveRecord::IdentityMap.instance_variable_get("@unclobbered")
    end
  end
end
