# frozen_string_literal: true

require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  context "foo and bar" do
    before do
      @foo = FooHabtm.create(name: "foo")
    end

    context "where the association is created between model versions" do
      before do
        @foo.update_attributes(name: "foo1", bar_habtms: [BarHabtm.create(name: "bar")])
      end

      context "when reified" do
        before do
          @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
        end

        it "see the associated as it was at the time" do
          expect(@reified.bar_habtms.length).to(eq(0))
        end

        it "not persist changes to the live association" do
          expect(@foo.reload.bar_habtms).not_to(eq(@reified.bar_habtms))
        end
      end
    end

    context "where the association is changed between model versions" do
      before do
        @foo.update_attributes(name: "foo2", bar_habtms: [BarHabtm.create(name: "bar2")])
        @foo.update_attributes(name: "foo3", bar_habtms: [BarHabtm.create(name: "bar3")])
      end

      context "when reified" do
        before do
          @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
        end

        it "see the association as it was at the time" do
          expect(@reified.bar_habtms.first.name).to(eq("bar2"))
        end

        it "not persist changes to the live association" do
          expect(@foo.reload.bar_habtms.first).not_to(eq(@reified.bar_habtms.first))
        end
      end

      context "when reified with has_and_belongs_to_many: false" do
        before { @reified = @foo.versions.last.reify }

        it "see the association as it is now" do
          expect(@reified.bar_habtms.first.name).to(eq("bar3"))
        end
      end
    end

    context "where the association is destroyed between model versions" do
      before do
        @foo.update_attributes(name: "foo2", bar_habtms: [BarHabtm.create(name: "bar2")])
        @foo.update_attributes(name: "foo3", bar_habtms: [])
      end

      context "when reified" do
        before do
          @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
        end

        it "see the association as it was at the time" do
          expect(@reified.bar_habtms.first.name).to(eq("bar2"))
        end

        it "not persist changes to the live association" do
          expect(@foo.reload.bar_habtms.first).not_to(eq(@reified.bar_habtms.first))
        end
      end
    end

    context "where the unassociated model changes" do
      before do
        @bar = BarHabtm.create(name: "bar2")
        @foo.update_attributes(name: "foo2", bar_habtms: [@bar])
        @foo.update_attributes(name: "foo3", bar_habtms: [BarHabtm.create(name: "bar4")])
        @bar.update_attributes(name: "bar3")
      end

      context "when reified" do
        before do
          @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
        end

        it "see the association as it was at the time" do
          expect(@reified.bar_habtms.first.name).to(eq("bar2"))
        end

        it "not persist changes to the live association" do
          expect(@foo.reload.bar_habtms.first).not_to(eq(@reified.bar_habtms.first))
        end
      end
    end
  end

  context "updated via nested attributes" do
    before do
      @foo = FooHabtm.create(name: "foo", bar_habtms_attributes: [{ name: "bar" }])
      @foo.update_attributes(
        name: "foo2",
        bar_habtms_attributes: [{ id: @foo.bar_habtms.first.id, name: "bar2" }]
      )
      @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
    end

    it "see the associated object as it was at the time" do
      expect(@reified.bar_habtms.first.name).to(eq("bar"))
    end

    it "not persist changes to the live object" do
      expect(@foo.reload.bar_habtms.first.name).not_to(eq(@reified.bar_habtms.first.name))
    end
  end
end
