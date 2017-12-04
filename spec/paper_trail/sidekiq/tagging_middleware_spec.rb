RSpec.describe(::PaperTrail::Sidekiq::TaggingMiddleware, versioning: true) do
  let(:config) do
    {
      whodunnit: 123,
      controller_info: { ip: :stubbed_ip }
    }
  end

  it "sets paper trail config for the duration of the sidekiq job" do
    allow(PaperTrail).to receive(:with_paper_trail_config)
    described_class.new(config).call(:stubbed_worker, :stubbed_msg, :stubbed_queue) { :stubbed_job }
    expect(PaperTrail).to have_received(:with_paper_trail_config).with(config)
  end
end
