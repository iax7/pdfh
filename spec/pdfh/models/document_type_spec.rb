# frozen_string_literal: true

RSpec.describe Pdfh::DocumentType do
  let(:valid_attributes) do
    {
      name: "Test Document",
      re_id: "test.*\\.pdf",
      re_date: "(\\d{2})\\/(?<m>\\w+)\\/(?<y>\\d{4})",
      store_path: "{YEAR}/Test",
      name_template: "{period} {original}"
    }
  end

  describe "#initialize" do
    context "with valid attributes" do
      subject { described_class.new(valid_attributes) }

      it "creates a new document type" do
        expect(subject).to be_a(described_class)
      end

      it "converts regex strings to actual regex objects" do
        expect(subject.re_id).to be_a(Regexp)
        expect(subject.re_date).to be_a(Regexp)
      end
    end

    context "with missing required fields" do
      it "creates instance but marks name as missing" do
        doc_type = described_class.new(valid_attributes.except(:name))
        expect(doc_type.missing_keys).to include(:name)
        expect(doc_type.missing_keys?).to be true
      end

      it "creates instance but marks re_date as missing" do
        doc_type = described_class.new(valid_attributes.except(:re_date))
        expect(doc_type.missing_keys).to include(:re_date)
        expect(doc_type.missing_keys?).to be true
      end

      it "creates instance but marks store_path as missing" do
        doc_type = described_class.new(valid_attributes.except(:store_path))
        expect(doc_type.missing_keys).to include(:store_path)
        expect(doc_type.missing_keys?).to be true
      end

      it "creates instance but marks multiple fields as missing" do
        doc_type = described_class.new(valid_attributes.except(:name, :re_date))
        expect(doc_type.missing_keys).to include(:name, :re_date)
        expect(doc_type.missing_keys?).to be true
      end
    end

    context "when re_id is not provided" do
      it "uses the name as default id regex" do
        doc_type = described_class.new(valid_attributes.except(:re_id))
        expect(doc_type.re_id).to be_a(Regexp)
        expect(doc_type.re_id.match?(doc_type.name)).to be true
      end
    end
  end

  describe "#valid?" do
    it "returns true for valid templates" do
      doc_type = described_class.new(valid_attributes)
      expect(doc_type.valid?).to be true
    end

    it "returns false for invalid tokens" do
      doc_type = described_class.new(valid_attributes.merge(store_path: "{INVALID_TOKEN}/Test"))
      expect(doc_type.valid?).to be false
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the document type" do
      doc_type = described_class.new(valid_attributes)
      hash = doc_type.to_h

      expect(hash).to be_a(Hash)
      expect(hash["name"]).to eq("Test Document")
      expect(hash["re_id"]).to be_a(Regexp)
    end
  end

  describe "#gid" do
    it "returns a sanitized identifier based on name" do
      doc_type = described_class.new(valid_attributes.merge(name: "Test This?%&"))
      expect(doc_type.gid).to eq("test-this")
    end

    it "converts spaces to dashes" do
      doc_type = described_class.new(valid_attributes.merge(name: "Multi Word Name"))
      expect(doc_type.gid).to eq("multi-word-name")
    end
  end
end
