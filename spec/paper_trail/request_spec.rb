# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe(Request, versioning: true) do
    describe ".enabled_for_model?" do
      it "returns true" do
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
      end
    end

    describe ".disable_model" do
      it "sets enabled_for_model? to false" do
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
        PaperTrail.request.disable_model(Widget)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(false)
      end

      after do
        PaperTrail.request.enable_model(Widget)
      end
    end

    describe ".enabled_for_model" do
      it "sets enabled_for_model? to true" do
        PaperTrail.request.enabled_for_model(Widget, false)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(false)
        PaperTrail.request.enabled_for_model(Widget, true)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
      end

      after do
        PaperTrail.request.enable_model(Widget)
      end
    end

    describe ".enabled_for_all_models?" do
      it "returns true" do
        expect(PaperTrail.request.enabled_for_all_models?).to eq(true)
      end
    end

    describe ".disable_all_models" do
      it "sets enabled_for_all_models? to false" do
        expect(PaperTrail.request.enabled_for_all_models?).to eq(true)
        PaperTrail.request.disable_all_models
        expect(PaperTrail.request.enabled_for_all_models?).to eq(false)
      end

      after do
        PaperTrail.request.enable_all_models
      end
    end

    describe ".enabled_for_all_models" do
      it "sets enabled_for_all_models? to true" do
        PaperTrail.request.enabled_for_all_models(false)
        expect(PaperTrail.request.enabled_for_all_models?).to eq(false)
        PaperTrail.request.enabled_for_all_models(true)
        expect(PaperTrail.request.enabled_for_all_models?).to eq(true)
      end

      after do
        PaperTrail.request.enable_all_models
      end
    end

    describe ".enabled_for_controller?" do
      it "returns true" do
        expect(PaperTrail.request.enabled_for_controller?).to eq(true)
      end
    end

    describe ".enabled_for_controller=" do
      it "sets enabled_for_controller? to true" do
        PaperTrail.request.enabled_for_controller = true
        expect(PaperTrail.request.enabled_for_controller?).to eq(true)
        PaperTrail.request.enabled_for_controller = false
        expect(PaperTrail.request.enabled_for_controller?).to eq(false)
      end

      after do
        PaperTrail.request.enabled_for_controller = true
      end
    end

    describe ".controller_info" do
      it "returns an empty hash" do
        expect(PaperTrail.request.controller_info).to eq({})
      end
    end

    describe ".controller_info=" do
      it "sets controller_info" do
        PaperTrail.request.controller_info = { foo: :bar }
        expect(PaperTrail.request.controller_info).to eq(foo: :bar)
      end

      after do
        PaperTrail.request.controller_info = {}
      end
    end

    describe ".enable_model" do
      it "sets enabled_for_model? to true" do
        PaperTrail.request.disable_model(Widget)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(false)
        PaperTrail.request.enable_model(Widget)
        expect(PaperTrail.request.enabled_for_model?(Widget)).to eq(true)
      end

      after do
        PaperTrail.request.enable_model(Widget)
      end
    end

    describe ".whodunnit" do
      context "when set to a proc" do
        it "evaluates the proc each time a version is made" do
          call_count = 0
          described_class.whodunnit = proc { call_count += 1 }
          expect(described_class.whodunnit).to eq(1)
          expect(described_class.whodunnit).to eq(2)
        end
      end

      context "when set to a primtive value" do
        it "returns the primitive value" do
          described_class.whodunnit = :some_whodunnit
          expect(described_class.whodunnit).to eq(:some_whodunnit)
        end
      end
    end

    describe ".with" do
      context "block given" do
        context "all allowed options" do
          it "sets options only for the block passed" do
            described_class.whodunnit = "some_whodunnit"
            described_class.enabled_for_model(Widget, true)

            described_class.with(whodunnit: "foo", enabled_for_Widget: false) do
              expect(described_class.whodunnit).to eq("foo")
              expect(described_class.enabled_for_model?(Widget)).to eq false
            end
            expect(described_class.whodunnit).to eq "some_whodunnit"
            expect(described_class.enabled_for_model?(Widget)).to eq true
          end

          it "sets options only for the current thread" do
            described_class.whodunnit = "some_whodunnit"
            described_class.enabled_for_model(Widget, true)

            described_class.with(whodunnit: "foo", enabled_for_Widget: false) do
              expect(described_class.whodunnit).to eq("foo")
              expect(described_class.enabled_for_model?(Widget)).to eq false
              Thread.new { expect(described_class.whodunnit).to be_nil }.join
              Thread.new { expect(described_class.enabled_for_model?(Widget)).to eq true }.join
            end
            expect(described_class.whodunnit).to eq "some_whodunnit"
            expect(described_class.enabled_for_model?(Widget)).to eq true
          end
        end

        context "some invalid options" do
          it "raises an invalid option error" do
            subject = proc do
              described_class.with(whodunnit: "blah", invalid_option: "foo") do
                raise "This block should not be reached"
              end
            end

            expect { subject.call }.to raise_error(PaperTrail::Request::InvalidOption) do |e|
              expect(e.message).to eq "Invalid option: invalid_option"
            end
          end
        end

        context "all invalid options" do
          it "raises an invalid option error" do
            subject = proc do
              described_class.with(invalid_option: "foo", other_invalid_option: "blah") do
                raise "This block should not be reached"
              end
            end

            expect { subject.call }.to raise_error(PaperTrail::Request::InvalidOption) do |e|
              expect(e.message).to eq "Invalid option: invalid_option"
            end
          end
        end

        context "private options" do
          it "raises an invalid option error" do
            subject = proc do
              described_class.with(transaction_id: "blah") do
                raise "This block should not be reached"
              end
            end

            expect { subject.call }.to raise_error(PaperTrail::Request::InvalidOption) do |e|
              expect(e.message).to eq "Cannot set private option: transaction_id"
            end
          end
        end
      end
    end

    describe "#without_versioning" do
      it "is thread-safe" do
        enabled = nil
        t1 = Thread.new do
          PaperTrail.request.without_versioning do
            sleep(0.01)
            enabled = PaperTrail.request.enabled_for_all_models?
            sleep(0.01)
          end
          enabled
        end
        # A second thread is timed so that it runs during the first thread's
        # `without_versioning` block.
        t2 = Thread.new do
          sleep(0.005)
          PaperTrail.request.enabled_for_all_models?
        end
        expect(t1.value).to eq(false)
        expect(t2.value).to eq(true) # see? unaffected by t1
        expect(PaperTrail.request.enabled_for_all_models?).to eq(true)
      end
    end
  end
end
