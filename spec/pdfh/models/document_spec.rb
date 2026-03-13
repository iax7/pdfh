# frozen_string_literal: true

RSpec.describe Pdfh::Document do
  include_context "with silent console"

  let(:doc_file) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:doc_type) { build(:document_type) }
  let(:text) { "del 06/Enero/2019 al 05/Febrero/2019" }
  let(:date_captures) { { "m" => "Enero", "y" => "2019", "d" => "06" } }

  subject(:document) { described_class.new(doc_file, doc_type, text, date_captures) }

  describe "#initialize" do
    it "stores text" do
      expect(document.text).to eq(text)
    end

    it "stores the document type" do
      expect(document.type).to eq(doc_type)
    end

    it "exposes a FileInfo sub-object" do
      expect(document.file_info).to be_a(Pdfh::FileInfo)
    end

    it "exposes a DateInfo sub-object" do
      expect(document.date_info).to be_a(Pdfh::DateInfo)
    end
  end

  describe "#to_s" do
    it "returns the file name" do
      expect(document.to_s).to eq("cuenta.pdf")
    end
  end

  describe "rename methods" do
    describe "#new_name" do
      it "generates new filename from template with extension" do
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

  describe "#type_name" do
    it "returns the document type name" do
      expect(document.type_name).to eq(doc_type.name)
    end

    context "when type is nil" do
      subject(:document) { described_class.new(doc_file, nil, text, date_captures) }

      it "returns N/A" do
        expect(document.type_name).to eq("N/A")
      end
    end
  end
end
