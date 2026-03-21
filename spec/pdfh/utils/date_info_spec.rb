# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfh::DateInfo do
  include_context "with silent console"

  let(:captures) { { "m" => "Enero", "y" => "2019", "d" => "06" } }

  subject(:date_info) { described_class.new(captures) }

  describe "#captures" do
    it "returns the raw captures hash" do
      expect(date_info.captures).to eq(captures)
    end
  end

  describe "#month" do
    it "normalizes a Spanish month name to a number" do
      expect(date_info.month).to eq(1)
    end

    context "when month is a zero-padded number" do
      let(:captures) { { "m" => "03", "y" => "2024" } }

      it "returns the integer value" do
        expect(date_info.month).to eq(3)
      end
    end
  end

  describe "#year" do
    it "returns a 4-digit year as integer" do
      expect(date_info.year).to eq(2019)
    end

    context "when provided as 2-digit year" do
      let(:captures) { { "m" => "03", "y" => "24" } }

      it "converts to 4-digit year prefixed with 20" do
        expect(date_info.year).to eq(2024)
      end
    end
  end

  describe "#day" do
    it "returns the captured day string" do
      expect(date_info.day).to eq("06")
    end

    context "when day is not captured" do
      let(:captures) { { "m" => "Enero", "y" => "2019" } }

      it "returns nil" do
        expect(date_info.day).to be_nil
      end
    end
  end

  describe "#quarter" do
    {
      1 => [1, 2, 3],
      2 => [4, 5, 6],
      3 => [7, 8, 9],
      4 => [10, 11, 12]
    }.each do |q, months|
      context "Q#{q}" do
        it "includes months #{months.join(", ")}" do
          months.each do |m|
            expect(described_class.new({ "m" => m.to_s, "y" => "2024" }).quarter).to eq(q)
          end
        end
      end
    end
  end

  describe "#bimester" do
    {
      1 => [1, 2],
      2 => [3, 4],
      3 => [5, 6],
      4 => [7, 8],
      5 => [9, 10],
      6 => [11, 12]
    }.each do |b, months|
      context "B#{b}" do
        it "includes months #{months.join(", ")}" do
          months.each do |m|
            expect(described_class.new({ "m" => m.to_s, "y" => "2024" }).bimester).to eq(b)
          end
        end
      end
    end
  end

  describe "#period" do
    it "formats as YYYY-MM with zero-padded month" do
      expect(date_info.period).to eq("2019-01")
    end

    context "when month needs padding" do
      let(:captures) { { "m" => "3", "y" => "2024" } }

      it "pads single-digit month with a leading zero" do
        expect(date_info.period).to eq("2024-03")
      end
    end
  end
end
