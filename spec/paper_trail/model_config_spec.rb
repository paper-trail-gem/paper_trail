# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe ModelConfig do
    describe "when has_paper_trail is called" do
      it "raises an error" do
        expect {
          class MisconfiguredCVC < ActiveRecord::Base
            has_paper_trail class_name: "AbstractVersion"
          end
        }.to raise_error(
          /use concrete \(not abstract\) version models/
        )
      end
    end

    describe "deprecated methods" do
      let(:config) { PaperTrail::ModelConfig.new(:some_model_class) }

      before do
        allow(ActiveSupport::Deprecation).to receive(:warn)
      end

      describe "disable" do
        it "delegates to request" do
          allow(PaperTrail.request).to receive(:disable_model)
          config.disable
          expect(PaperTrail.request).to have_received(:disable_model).with(:some_model_class)
          expect(ActiveSupport::Deprecation).to have_received(:warn)
        end
      end

      describe "enable" do
        it "delegates to request" do
          allow(PaperTrail.request).to receive(:enable_model)
          config.enable
          expect(PaperTrail.request).to have_received(:enable_model).with(:some_model_class)
          expect(ActiveSupport::Deprecation).to have_received(:warn)
        end
      end

      describe "enabled?" do
        it "delegates to request" do
          allow(PaperTrail.request).to receive(:enabled_for_model?)
          config.enabled?
          expect(PaperTrail.request).to have_received(:enabled_for_model?).with(:some_model_class)
          expect(ActiveSupport::Deprecation).to have_received(:warn)
        end
      end
    end
  end
end
