# frozen_string_literal: true

require "base64"

RSpec.describe Pdfh::DocumentType do
  let(:valid_attributes) do
    {
      name: "Test Document",
      re_file: "test.*\\.pdf",
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
        expect(subject.re_file).to be_a(Regexp)
        expect(subject.re_date).to be_a(Regexp)
      end

      it "sets default name_template if not provided" do
        doc_type = described_class.new(valid_attributes.except(:name_template))
        expect(doc_type.name_template).to eq("{original}")
      end
    end

    context "with sub_types" do
      let(:attributes_with_subtypes) do
        valid_attributes.merge(
          sub_types: [
            { name: "SubType1", month_offset: 1, re_date: "\\d{2}-(?<m>\\d{2})-(?<y>\\d{4})" },
            { name: "SubType2", month_offset: 0 }
          ]
        )
      end

      it "extracts sub_types into DocumentSubType objects" do
        doc_type = described_class.new(attributes_with_subtypes)
        expect(doc_type.sub_types.size).to eq(2)
        expect(doc_type.sub_types.first).to be_a(Pdfh::DocumentSubType)
        expect(doc_type.sub_types.first.name).to eq("SubType1")
        expect(doc_type.sub_types.first.month_offset).to eq(1)
      end

      it "converts sub_type re_date to a Regexp" do
        doc_type = described_class.new(attributes_with_subtypes)
        expect(doc_type.sub_types.first.re_date).to be_a(Regexp)
      end
    end

    context "with invalid validators" do
      it "raises ArgumentError when store_path contains invalid tokens" do
        attributes = valid_attributes.merge(store_path: "{INVALID_TOKEN}/Test")
        expect do
          described_class.new(attributes)
        end.to raise_error(ArgumentError, /invalid store_path/)
      end

      it "raises ArgumentError when name_template contains invalid tokens" do
        attributes = valid_attributes.merge(name_template: "{INVALID_TOKEN} test")
        expect do
          described_class.new(attributes)
        end.to raise_error(ArgumentError, /invalid name_template/)
      end
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the document type" do
      doc_type = described_class.new(valid_attributes)
      hash = doc_type.to_h

      expect(hash).to be_a(Hash)
      expect(hash["name"]).to eq("Test Document")
      expect(hash["re_file"]).to be_a(Regexp)
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

  describe "#sub_type" do
    let(:doc_type_with_subtypes) do
      described_class.new(
        valid_attributes.merge(
          sub_types: [
            { name: "SubType1" },
            { name: "SubType2" }
          ]
        )
      )
    end

    it "returns the matching subtype based on text content" do
      expect(doc_type_with_subtypes.sub_type("contains SubType1 here")).to eq(doc_type_with_subtypes.sub_types.first)
    end

    it "returns nil when no subtype matches" do
      expect(doc_type_with_subtypes.sub_type("no match here")).to be_nil
    end

    it "handles case-insensitive matching" do
      expect(doc_type_with_subtypes.sub_type("contains subtype1 here")).to eq(doc_type_with_subtypes.sub_types.first)
    end
  end

  describe "#password" do
    context "with Base64 encoded password" do
      let(:original_password) { "secretpassword" }
      let(:encoded_password) { Base64.strict_encode64(original_password) }
      let(:doc_type) { described_class.new(valid_attributes.merge(pwd: encoded_password)) }

      it "decodes the Base64 encoded password" do
        expect(doc_type.password).to eq(original_password)
      end
    end

    context "with plain text password" do
      let(:plain_password) { "plain123!" }
      let(:doc_type) { described_class.new(valid_attributes.merge(pwd: plain_password)) }

      it "returns the password as is" do
        expect(doc_type.password).to eq(plain_password)
      end
    end
  end

  describe "#generate_new_name" do
    it "replaces tokens in name_template with provided values" do
      doc_type = described_class.new(valid_attributes)
      values = { period: "2023-01", original: "document.pdf" }
      expect(doc_type.generate_new_name(values)).to eq("2023-01 document.pdf")
    end
  end

  describe "#generate_path" do
    it "replaces tokens in store_path with provided values" do
      doc_type = described_class.new(valid_attributes)
      values = { year: "2023" }
      expect(doc_type.generate_path(values)).to eq("2023/Test")
    end
  end
end
