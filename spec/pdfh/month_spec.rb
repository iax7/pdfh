# frozen_string_literal: true

RSpec.describe Pdfh::Month do
  describe "#normalize_to_i" do
    context "when param is a number 02" do
      subject { described_class.normalize_to_i("02") }

      it { is_expected.to eq(2) }
    end

    context "when param is a 3 digit month 'feb'" do
      subject { described_class.normalize_to_i("feb") }

      it { is_expected.to eq(2) }
    end

    context "when param is spanish month 'febrero'" do
      subject { described_class.normalize_to_i("febrero") }

      it { is_expected.to eq(2) }
    end

    context "when param is english month 'February'" do
      subject { described_class.normalize_to_i("February") }

      it { is_expected.to eq(2) }
    end

    it "when param number is a not a valid month number '15'" do
      expect { described_class.normalize_to_i("15") }.to raise_error(%(Month "15" is not a valid month number))
    end

    it "when param is a no existing month name 'abcdef'" do
      expect { described_class.normalize_to_i("abcdef") }.to raise_error(%(Month "abcdef" is not valid))
    end
  end
end
