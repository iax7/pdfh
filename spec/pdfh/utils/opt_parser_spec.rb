# frozen_string_literal: true

RSpec.describe Pdfh::OptParser do
  describe "#parse_argv" do
    context "when ARGV is empty" do
      let(:defaults) do
        { dry: false, verbose: false }
      end

      it "Empty options" do
        expect(described_class.parse_argv).to eq(defaults)
      end
    end
  end

  describe "#version" do
    it "Prints" do
      expect { described_class.version }.to output(/rspec v\d\.\d\.\d/).to_stdout
    end
  end

  describe "#help" do
    it "Prints" do
      expect { described_class.help }.to output(/Specific options:/).to_stdout
    end
  end

  describe "#list_types" do
    let(:expected) { /\s+ID\s+Type Name\n\s+———————————— {2}———————————————————————\n/ }

    it "Prints" do
      expect { described_class.list_types }.to output(expected).to_stdout
    end
  end

  context "when an invalid option is provided" do
    before do
      allow(Pdfh::OptParser::OPT_PARSER).to receive(:parse!).and_raise(
        OptionParser::InvalidOption.new("invalid option: --invalid-option")
      )
      allow(Pdfh).to receive(:error_print)
      allow(described_class).to receive(:exit).with(1)
      allow(described_class).to receive(:puts)
    end

    it "handles invalid options and exits with status 1" do
      expect(Pdfh).to receive(:error_print).with(/invalid option/, hash_including(:exit_app => false))
      expect(described_class).to receive(:exit).with(1)

      described_class.parse_argv
    end
  end
end
