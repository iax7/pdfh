# frozen_string_literal: true

RSpec.describe Pdfh::DocumentPeriod do
  context "when month is incorrect" do
    subject(:main) { described_class.new(month: "wrong", year: 2021, month_offset: -1) }

    it "raises an exception" do
      expect { main }.to raise_error("Month \"wrong\" is not valid")
    end
  end

  context "when month offset is -1" do
    subject { described_class.new(month: 1, year: 2021, month_offset: -1).to_s }

    it { is_expected.to eq("2020-12") }
  end

  context "when month offset is +1" do
    subject { described_class.new(month: 12, year: 2020, month_offset: +1).to_s }

    it { is_expected.to eq("2021-01") }
  end

  context "when no month offset" do
    subject { described_class.new(month: 5, year: 2021, month_offset: 0).to_s }

    it { is_expected.to eq("2021-05") }
  end

  describe "#month" do
    # @return [Integer]
    def month(param)
      described_class.new(month: param, year: 2021, month_offset: 0).month
    end

    it "month '1' => 1" do
      expect(month("1")).to eq(1)
    end

    it "month 'ene' => 1" do
      expect(month("ene")).to eq(1)
    end

    it "month 'enero' => 1" do
      expect(month("enero")).to eq(1)
    end

    it "month 'jan' => 1" do
      expect(month("jan")).to eq(1)
    end

    it "month 'january'=> 1" do
      expect(month("january")).to eq(1)
    end
  end

  describe "#year" do
    # @return [Integer]
    def year(param)
      described_class.new(month: 1, year: param, month_offset: 0).year
    end

    it { expect(year("2021")).to eq(2021) }
    it { expect(year("21")).to eq(2021) }
    it { expect(year("19")).to eq(2019) }
  end
end
