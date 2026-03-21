# frozen_string_literal: true

RSpec.describe Pdfh::Settings do
  let(:invoice_doc_type) do
    build(:document_type,
          name: "Invoice",
          re_id: /invoice/,
          store_path: "{year}/Invoices")
  end

  let(:receipt_doc_type) do
    build(:document_type,
          name: "Receipt",
          re_id: /receipt/,
          store_path: "{year}/Receipts")
  end

  let(:document_types_hash) { { invoice_doc_type.gid => invoice_doc_type } }

  subject(:settings) do
    described_class.new(
      lookup_dirs: [Dir.tmpdir],
      base_path: Dir.tmpdir,
      document_types: document_types_hash
    )
  end

  describe "#initialize" do
    it "stores lookup_dirs" do
      expect(settings.lookup_dirs).to eq([Dir.tmpdir])
    end

    it "stores base_path" do
      expect(settings.base_path).to eq(Dir.tmpdir)
    end
  end

  describe "#document_types" do
    it "returns array of all document types" do
      expect(settings.document_types).to be_an(Array)
      expect(settings.document_types.size).to eq(1)
    end

    it "returns DocumentType instances" do
      expect(settings.document_types).to all(be_a(Pdfh::DocumentType))
    end

    context "with multiple document types" do
      let(:document_types_hash) do
        {
          invoice_doc_type.gid => invoice_doc_type,
          receipt_doc_type.gid => receipt_doc_type
        }
      end

      it "returns all document types" do
        expect(settings.document_types.size).to eq(2)
      end
    end
  end

  describe "#document_type" do
    it "returns document type by gid" do
      doc_type = settings.document_type("invoice")
      expect(doc_type).to be_a(Pdfh::DocumentType)
      expect(doc_type.name).to eq("Invoice")
    end

    it "returns nil for non-existent gid" do
      expect(settings.document_type("non_existent")).to be_nil
    end
  end

  describe "#document_types_name_max_size" do
    it "returns the max name length" do
      expect(settings.document_types_name_max_size).to eq(7) # "Invoice"
    end

    context "with multiple document types" do
      let(:document_types_hash) do
        {
          invoice_doc_type.gid => invoice_doc_type,
          receipt_doc_type.gid => receipt_doc_type
        }
      end

      it "returns the max name length across all types" do
        expect(settings.document_types_name_max_size).to eq(7) # "Invoice" and "Receipt" both 7
      end
    end

    context "with no document types" do
      let(:document_types_hash) { {} }

      it "returns 0" do
        expect(settings.document_types_name_max_size).to eq(0)
      end
    end
  end
end
