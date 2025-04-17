# frozen_string_literal: true

RSpec.describe Pdfh::Main do
  include_context "with silent console"

  describe "#start" do
    before do
      allow($stdout).to receive(:puts)
    end

    context "when no provided files" do
      let(:settings_path) { File.expand_path("spec/fixtures/settings.yml") }
      let(:files) { ["EdoCta (1).pdf", "dummy.pdf"] }
      let(:type_cta) { build(:document_type) }
      let(:document) { build(:document) }

      it "loads" do
        allow(Dir).to receive(:[]).and_return(files)

        allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with("EdoCta (1).pdf").and_return(type_cta)
        allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with("dummy.pdf").and_return(nil)
        allow(Pdfh::Document).to receive(:new).with("EdoCta (1).pdf", anything).and_return(document)

        expect(described_class.start).not_to be_nil
      end
    end

    context "when provided files" do
      let(:options) { attributes_for(:options, :file_mode) }

      it "loads" do
        allow(Pdfh::OptParser).to receive(:parse_argv).and_return(options)
        expect(described_class.start).to eq(options[:files])
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

        described_class.start
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

          described_class.start
        end
      end
    end
  end
end
