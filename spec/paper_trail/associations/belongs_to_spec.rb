# frozen_string_literal: true

require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  context "wotsit belongs_to widget" do
    before { @widget = Widget.create(name: "widget_0") }

    context "where the association is created between model versions" do
      before do
        @wotsit = Wotsit.create(name: "wotsit_0")
        @wotsit.update(widget_id: @widget.id, name: "wotsit_1")
      end

      context "when reified" do
        before { @wotsit0 = @wotsit.versions.last.reify(belongs_to: true) }

        it "see the associated as it was at the time" do
          expect(@wotsit0.widget).to be_nil
        end

        it "not persist changes to the live association" do
          expect(@wotsit.reload.widget).to(eq(@widget))
        end
      end

      context "and then the associated is updated between model versions" do
        before do
          @widget.update(name: "widget_1")
          @widget.update(name: "widget_2")
          @wotsit.update(name: "wotsit_2")
          @widget.update(name: "widget_3")
        end

        context "when reified" do
          before { @wotsit1 = @wotsit.versions.last.reify(belongs_to: true) }

          it "see the associated as it was at the time" do
            expect(@wotsit1.widget.name).to(eq("widget_2"))
          end

          it "not persist changes to the live association" do
            expect(@wotsit.reload.widget.name).to(eq("widget_3"))
          end
        end

        context "when reified opting out of belongs_to reification" do
          before { @wotsit1 = @wotsit.versions.last.reify(belongs_to: false) }

          it "see the associated as it is live" do
            expect(@wotsit1.widget.name).to(eq("widget_3"))
          end
        end
      end

      context "and then the associated is destroyed" do
        before do
          @wotsit.update(name: "wotsit_2")
          @widget.destroy
        end

        context "when reified with belongs_to: true" do
          before { @wotsit2 = @wotsit.versions.last.reify(belongs_to: true) }

          it "see the associated as it was at the time" do
            expect(@wotsit2.widget).to(eq(@widget))
          end

          it "not persist changes to the live association" do
            expect(@wotsit.reload.widget).to be_nil
          end

          it "be able to persist the reified record" do
            expect { @wotsit2.save! }.not_to(raise_error)
          end
        end

        context "when reified with belongs_to: false" do
          before { @wotsit2 = @wotsit.versions.last.reify(belongs_to: false) }

          it "save should not re-create the widget record" do
            @wotsit2.save!
            expect(::Widget.find_by(id: @widget.id)).to be_nil
          end
        end

        context "and then the model is updated" do
          before do
            @wotsit.update(name: "wotsit_3")
          end

          context "when reified" do
            before { @wotsit2 = @wotsit.versions.last.reify(belongs_to: true) }

            it "see the associated as it was the time" do
              expect(@wotsit2.widget).to be_nil
            end
          end
        end
      end
    end

    context "where the association is changed between model versions" do
      before do
        @wotsit = @widget.create_wotsit(name: "wotsit_0")
        @new_widget = Widget.create(name: "new_widget")
        @wotsit.update(widget_id: @new_widget.id, name: "wotsit_1")
      end

      context "when reified" do
        before { @wotsit0 = @wotsit.versions.last.reify(belongs_to: true) }

        it "see the association as it was at the time" do
          expect(@wotsit0.widget.name).to(eq("widget_0"))
        end

        it "not persist changes to the live association" do
          expect(@wotsit.reload.widget).to(eq(@new_widget))
        end
      end

      context "when reified with option mark_for_destruction" do
        before do
          @wotsit0 = @wotsit.versions.last.reify(belongs_to: true, mark_for_destruction: true)
        end

        it "does not mark the new associated for destruction" do
          expect(@new_widget.marked_for_destruction?).to(eq(false))
        end
      end
    end
  end
end
