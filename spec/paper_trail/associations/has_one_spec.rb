# frozen_string_literal: true

require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  after do
    Timecop.return
  end

  describe "widget, reified from a version prior to creation of wotsit" do
    it "has a nil wotsit" do
      widget = Widget.create(name: "widget_0")
      widget.update_attributes(name: "widget_1")
      widget.create_wotsit(name: "wotsit_0")
      widget0 = widget.versions.last.reify(has_one: true)
      expect(widget0.wotsit).to be_nil
    end
  end

  describe "widget, reified from a version after creation of wotsit" do
    it "has the expected wotsit" do
      widget = Widget.create(name: "widget_0")
      wotsit = widget.create_wotsit(name: "wotsit_0")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_1")
      widget0 = widget.versions.last.reify(has_one: true)
      expect(widget0.wotsit.name).to(eq("wotsit_0"))
      expect(widget.reload.wotsit).to(eq(wotsit))
    end
  end

  describe "widget, reified from a version after its wotsit has been updated" do
    it "has the expected wotsit" do
      widget = Widget.create(name: "widget_0")
      wotsit = widget.create_wotsit(name: "wotsit_0")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_1")
      wotsit.update_attributes(name: "wotsit_1")
      wotsit.update_attributes(name: "wotsit_2")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_2")
      wotsit.update_attributes(name: "wotsit_3")
      widget1 = widget.versions.last.reify(has_one: true)
      expect(widget1.wotsit.name).to(eq("wotsit_2"))
      expect(widget.reload.wotsit.name).to(eq("wotsit_3"))
    end
  end

  describe "widget, reified with has_one: false" do
    it "has the latest wotsit in the database" do
      widget = Widget.create(name: "widget_0")
      wotsit = widget.create_wotsit(name: "wotsit_0")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_1")
      wotsit.update_attributes(name: "wotsit_1")
      wotsit.update_attributes(name: "wotsit_2")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_2")
      wotsit.update_attributes(name: "wotsit_3")
      widget1 = widget.versions.last.reify(has_one: false)
      expect(widget1.wotsit.name).to(eq("wotsit_3"))
    end
  end

  describe "widget, reified from a version prior to the destruction of its wotsit" do
    it "has the wotsit" do
      widget = Widget.create(name: "widget_0")
      wotsit = widget.create_wotsit(name: "wotsit_0")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_1")
      wotsit.destroy
      widget1 = widget.versions.last.reify(has_one: true)
      expect(widget1.wotsit).to(eq(wotsit))
      expect(widget.reload.wotsit).to be_nil
    end
  end

  describe "widget, refied from version after its wotsit was destroyed" do
    it "has a nil wotsit" do
      widget = Widget.create(name: "widget_0")
      wotsit = widget.create_wotsit(name: "wotsit_0")
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_1")
      wotsit.destroy
      Timecop.travel(1.second.since)
      widget.update_attributes(name: "widget_3")
      widget2 = widget.versions.last.reify(has_one: true)
      expect(widget2.wotsit).to be_nil
    end
  end
end
