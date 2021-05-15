# frozen_string_literal: true

RSpec.describe Pdfh do
  before { allow($stdout).to receive(:puts).and_return(nil) }

  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  it "#headline" do
    expect(described_class.headline("testing")).to eq(nil)
  end

  it "#error_print" do
    error = StandardError.new("Testing")
    expect { described_class.error_print(error) }.to raise_error SystemExit
  end

  it "#ident_print" do
    expect(described_class.ident_print("field name", "value", color: :blue)).to eq(nil)
  end

  describe "#search_config_file" do
    it "fails to find a configuration file" do
      expect { described_class.search_config_file }.to raise_error(Pdfh::SettingsIOError)
    end
  end

  context "when dry mode is on" do
    before { described_class.dry = true }

    it "is true" do
      expect(described_class.dry?).to be true
    end
  end

  context "when ARGV are empty" do
    it "Empty options" do
      expect(described_class.parse_argv).to eq({})
    end
  end
end
