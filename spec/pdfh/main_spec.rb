# frozen_string_literal: true

RSpec.describe Pdfh::Main do
  include_context "with silent console"

  describe "#start" do
    let(:files) { ["EdoCta (1).pdf", "dummy.pdf"] }

    before do
      # prevent silent console contest from being override
      allow(described_class).to receive(:assign_global_utils)
    end

    context "when no provided files (NORMAL)" do
      let(:settings_path) { File.expand_path("spec/fixtures/settings.yml") }
      let(:type_cta) { build(:document_type) }
      let(:document) { build(:document) }

      it "loads" do
        allow(Dir).to receive(:[]).and_return(files)

        expect(described_class.start(argv: [])).not_to be_nil
      end
    end

    context "when provided files" do
      let(:options) { attributes_for(:options, :file_mode) }
      let(:parser) { instance_double(Pdfh::OptParser, parse_argv: options) }

      it "loads" do
        allow(Pdfh::OptParser).to receive(:new).and_return(parser)
        expect(described_class.start(argv: files)).to eq(options[:files])
      end
    end

    context "when SettingsIOError occurs" do
      let(:error_message) { "Settings file not found" }

      before do
        allow(Pdfh::OptParser).to receive(:parse_argv).and_return({})
        allow(Pdfh::Options).to receive(:new).and_return(instance_double(Pdfh::Options, verbose?: false,
                                                                                        file_mode?: false))
        allow(Pdfh::SettingsBuilder).to receive(:build).and_raise(Pdfh::SettingsIOError, error_message)
        allow(Pdfh).to receive(:print_options)
        allow(Pdfh).to receive(:error_print)
        allow(Pdfh).to receive(:create_settings_file)
      end

      it "handles SettingsIOError and creates a new settings file" do
        expect(Pdfh).to receive(:error_print).with(error_message, exit_app: false)
        expect(Pdfh).to receive(:create_settings_file)
        expect(described_class).to receive(:exit).with(1)

        described_class.start(argv: [])
      end
    end

    context "when StandardError occurs" do
      let(:error_message) { "Standard error occurred" }
      let(:error) { StandardError.new(error_message) }
      let(:backtrace) { %w[line1 line2] }

      before do
        allow(Pdfh::OptParser).to receive(:parse_argv).and_return({})
        allow(Pdfh::Options).to receive(:new).and_return(instance_double(Pdfh::Options, verbose?: verbose,
                                                                                        file_mode?: false))
        allow(Pdfh::SettingsBuilder).to receive(:build).and_raise(error)
        allow(error).to receive(:backtrace).and_return(backtrace)
        allow(Pdfh).to receive(:print_options)
        allow(Pdfh).to receive(:error_print)
        allow(Pdfh).to receive(:verbose?).and_return(verbose)
      end

      context "when verbose mode is enabled" do
        let(:verbose) { true }

        it "prints backtrace and error message" do
          expect(Pdfh).to receive(:backtrace_print).with(error)
          expect(Pdfh).to receive(:error_print).with(error_message)

          described_class.start(argv: [])
        end
      end
    end
  end

  describe "#assign_global_utils" do
    let(:options) { instance_double(Pdfh::Options, verbose?: true) }
    let(:console) { instance_double(Pdfh::Console) }

    before do
      allow(Pdfh::Console).to receive(:new).and_return(console)
    end

    it "sets the global options and console" do
      expect(Pdfh).to receive(:instance_variable_set).with(:@options, options)
      expect(Pdfh).to receive(:instance_variable_set).with(:@console, console)

      described_class.send(:assign_global_utils, options)
    end
  end
end
