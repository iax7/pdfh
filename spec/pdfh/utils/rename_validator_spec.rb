# frozen_string_literal: true

RSpec.describe Pdfh::RenameValidator do
  subject(:validator) { described_class.new(name_template) }

  let(:name_template) { "document {original}-{period}-{YEAR}-{month}-{type}-{subtype}-{extra}" }

  describe "#initialize" do
    context "when name template is all valid" do
      it "all valid" do
        expect(validator.all).to eq(validator.valid)
      end

      it "unknown is empty" do
        expect(validator.unknown).to be_empty
      end

      it "object is valid" do
        expect(validator).to be_valid
      end
    end

    context "when name template contains unknown" do
      let(:name_template) { "{strange}" }

      it "all contains unknown" do
        expect(validator.all).to eq(%w[strange])
      end

      it "unknown contains strange" do
        expect(validator.unknown).to eq(%w[strange])
      end

      it "valid is empty" do
        expect(validator.valid).to be_empty
      end

      it "object is invalid" do
        expect(validator).not_to be_valid
      end
    end
  end

  describe "#types" do
    it "returns the keys of RENAME_TYPES" do
      expect(validator.types).to eq(%w[original period year month type subtype extra])
    end
  end

  describe "#gsub" do
    let(:values) do
      { original: "orig", period: "2022-03", year: 2024, month: 7, type: "invoice", subtype: "electricity",
     extra: "extra" }.freeze
    end

    it "returns a new name based on the name template and provided values" do
      expect(validator.gsub(values)).to eq("document orig-2022-03-2024-7-invoice-electricity-extra")
    end
  end
end
