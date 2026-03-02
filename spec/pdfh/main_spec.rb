# frozen_string_literal: true

RSpec.describe Pdfh::Main do
  let(:mock_logger) do
    instance_double(Pdfh::Console,
                    verbose?: false).tap do |logger|
      allow(logger).to receive(:print_options)
      allow(logger).to receive(:info)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:error_print)
      allow(logger).to receive(:backtrace_print)
    end
  end

  before do
    # Mock Console.new to return our mock logger
    allow(Pdfh::Console).to receive(:new).and_return(mock_logger)
  end

  describe "#start" do
    before do
      allow(Pdfh::Services::SettingsBuilder).to receive(:call).and_return(
        instance_double(Pdfh::Settings, lookup_dirs: [], document_types: [], base_path: "/tmp")
      )
      allow(Pdfh::Services::DirectoryScanner).to receive(:new).and_return(
        instance_double(Pdfh::Services::DirectoryScanner, scan: [])
      )
    end

    it "loads successfully" do
      expect(described_class.start(argv: [])).to be_nil
    end

    context "when SettingsIOError occurs" do
      let(:error_message) { "Settings file not found" }

      before do
        allow(Pdfh::Services::SettingsBuilder).to receive(:call).and_raise(Pdfh::SettingsIOError, error_message)
      end

      it "handles SettingsIOError" do
        expect(mock_logger).to receive(:error_print).with(error_message, exit_app: false)
        expect { described_class.start(argv: []) }.to raise_error(SystemExit)
      end
    end

    context "when StandardError occurs" do
      let(:error_message) { "Standard error occurred" }
      let(:error) { StandardError.new(error_message) }

      before do
        allow(Pdfh::Services::SettingsBuilder).to receive(:call).and_raise(error)
      end

      it "prints error message" do
        expect(mock_logger).to receive(:error_print).with(error_message)
        described_class.start(argv: [])
      end
    end
  end
end
