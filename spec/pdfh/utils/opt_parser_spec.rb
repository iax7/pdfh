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
      expect { described_class.version }.to output("rspec v3.0.1\n").to_stdout
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
end
