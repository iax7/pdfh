# frozen_string_literal: true

RSpec.describe Pdfh::OptParser do
  context "when ARGV are empty" do
    let(:defaults) do
      { dry: false, verbose: false }
    end

    it "Empty options" do
      expect(described_class.parse_argv).to eq(defaults)
    end
  end
end
