# frozen_string_literal: true

RSpec.describe Pdfh::Services::OptParser do
  let(:console) do
    instance_double("Pdfh::Console",
                    error_print: nil,
                    info: nil,
                    debug: nil,
                    backtrace_print: nil)
  end
  let(:parser) { described_class.new(argv: argv, console: console) }

  describe "#initialize" do
    let(:argv) { [] }

    it "sets default values" do
      expect(parser.instance_variable_get(:@options)).to include(
        verbose: false,
        dry: false
      )
    end
  end

  describe "#parse_argv" do
    context "with verbose flag" do
      let(:argv) { ["-v"] }

      it "sets verbose option to true" do
        expect(parser.parse_argv).to include(verbose: true)
      end
    end

    context "with dry run flag" do
      let(:argv) { ["-d"] }

      it "sets dry option to true" do
        expect(parser.parse_argv).to include(dry: true)
      end

      it "accepts long form flag" do
        parser = described_class.new(argv: ["--dry"], console: console)
        expect(parser.parse_argv).to include(dry: true)
      end
    end

    context "with invalid option" do
      let(:argv) { ["--invalid-option"] }

      it "handles invalid options, shows help, and exits with status 1" do
        allow_any_instance_of(OptionParser).to receive(:parse!).and_raise(OptionParser::InvalidOption, "error")
        expect(console).to receive(:error_print).with("invalid option: error", exit_app: false)
        expect(console).to receive(:info)

        expect { parser.parse_argv }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "with special commands" do
      let(:settings) { instance_double("Settings") }

      before do
        stub_const("Pdfh::VERSION", "1.2.3")
        allow(Pdfh::Services::SettingsBuilder).to receive(:call).and_return(settings)
      end

      context "with help option" do
        let(:argv) { ["--help"] }

        it "displays help and exits" do
          expect(console).to receive(:info)
          expect { parser.parse_argv }.to raise_error(SystemExit)
        end
      end

      context "with version option" do
        let(:argv) { ["-V"] }

        it "displays version and exits" do
          expect(console).to receive(:info).with(/v1\.2\.3/)
          expect { parser.parse_argv }.to raise_error(SystemExit)
        end
      end

      context "with list-types option" do
        let(:argv) { ["--list-types"] }
        let(:doc_type1) { instance_double("DocumentType", gid: "invoice", name: "Invoice") }
        let(:doc_type2) { instance_double("DocumentType", gid: "receipt", name: "Receipt") }

        before do
          allow(settings).to receive(:document_types).and_return([doc_type1, doc_type2])
        end

        it "lists document types and exits" do
          expect { parser.parse_argv }.to raise_error(SystemExit)
        end
      end
    end
  end
end
