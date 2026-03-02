# frozen_string_literal: true

RSpec.describe Pdfh::Document do
  include_context "with silent console"

  let(:doc_file) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:doc_type) { build(:document_type) }
  let(:text) { "del 06/Enero/2019 al 05/Febrero/2019" }
  let(:date_captures) { { "m" => "Enero", "y" => "2019", "d" => "06" } }

  subject(:document) { described_class.new(doc_file, doc_type, text, date_captures) }

  describe "#initialize" do
    it "stores text and date captures" do
      expect(document.text).to eq(text)
      expect(document.date_captures).to eq(date_captures)
    end
  end

  describe "file methods" do
    it "returns filename without extension" do
      expect(document.file_name_only).to eq("cuenta")
    end

    it "returns full filename" do
      expect(document.file_name).to eq("cuenta.pdf")
    end

    it "adds .bkp extension to backup name" do
      expect(document.backup_name).to eq("cuenta.pdf.bkp")
    end

    it "returns .pdf extension" do
      expect(document.file_extension).to eq(".pdf")
    end

    it "returns directory path" do
      expect(document.home_dir).to be_a(String)
    end

    it "returns filename as string" do
      expect(document.to_s).to eq("cuenta.pdf")
    end
  end

  describe "date methods" do
    describe "#month" do
      it "normalizes month name to number" do
        expect(document.month).to eq(1) # Enero = January = 1
      end
    end

    describe "#year" do
      it "returns 4-digit year" do
        expect(document.year).to eq(2019)
      end

      context "when provided as 2-digit year" do
        let(:date_captures) { { "m" => "03", "y" => "24" } }

        it "converts to 4-digit year" do
          expect(document.year).to eq(2024)
        end
      end

      context "when provided as 4-digit year" do
        let(:date_captures) { { "m" => "03", "y" => "2024" } }

        it "keeps 4-digit year as is" do
          expect(document.year).to eq(2024)
        end
      end
    end

    describe "#day" do
      it "returns captured day" do
        expect(document.day).to eq("06")
      end

      context "when day is not captured" do
        let(:date_captures) { { "m" => "Enero", "y" => "2019" } }

        it "returns nil" do
          expect(document.day).to be_nil
        end
      end
    end

    describe "#period" do
      it "formats as YYYY-MM with zero-padded month" do
        expect(document.period).to eq("2019-01")
      end
    end

    describe "#quarter" do
      it "calculates correct quarter from month" do
        expect(document.quarter).to eq(1) # Enero = Q1
      end

      {
        1 => [1, 2, 3],
        2 => [4, 5, 6],
        3 => [7, 8, 9],
        4 => [10, 11, 12]
      }.each do |quarter_num, months|
        context "Q#{quarter_num}" do
          it "includes months #{months.join(", ")}" do
            months.each do |m|
              doc = described_class.new(doc_file, doc_type, text, { "m" => m.to_s, "y" => "2024" })
              expect(doc.quarter).to eq(quarter_num)
            end
          end
        end
      end
    end

    describe "#bimester" do
      it "calculates correct bimester from month" do
        expect(document.bimester).to eq(1) # Enero = B1
      end

      {
        1 => [1, 2],
        2 => [3, 4],
        3 => [5, 6],
        4 => [7, 8],
        5 => [9, 10],
        6 => [11, 12]
      }.each do |bimester_num, months|
        context "B#{bimester_num}" do
          it "includes months #{months.join(", ")}" do
            months.each do |m|
              doc = described_class.new(doc_file, doc_type, text, { "m" => m.to_s, "y" => "2024" })
              expect(doc.bimester).to eq(bimester_num)
            end
          end
        end
      end
    end
  end

  describe "#rename_data" do
    it "returns hash with all template values" do
      data = document.rename_data

      expect(data).to include(
        original: "cuenta",
        period: "2019-01",
        year: "2019",
        month: "1",
        quarter: "Q1",
        bimester: "B1",
        name: doc_type.name,
        day: "06"
      )
    end

    it "returns frozen hash" do
      expect(document.rename_data).to be_frozen
    end
  end

  describe "#new_name" do
    it "generates new filename from template" do
      expect(document.new_name).to be_a(String)
      expect(document.new_name).to end_with(".pdf")
    end
  end

  describe "#store_path" do
    it "generates store path from template" do
      expect(document.store_path).to be_a(String)
    end
  end
end
