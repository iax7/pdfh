# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfh::FileInfo do
  include_context "with silent console"

  let(:file_path) { File.expand_path("spec/fixtures/cuenta.pdf") }

  subject(:file_info) { described_class.new(file_path) }

  describe "#path" do
    it "returns the full path to the file" do
      expect(file_info.path).to eq(file_path)
    end
  end

  describe "#stem" do
    it "returns file name without extension" do
      expect(file_info.stem).to eq("cuenta")
    end

    it "is aliased as name_only" do
      expect(file_info.name_only).to eq("cuenta")
    end
  end

  describe "#extension" do
    it "returns the extension with dot" do
      expect(file_info.extension).to eq(".pdf")
    end
  end

  describe "#name" do
    it "returns the full file name" do
      expect(file_info.name).to eq("cuenta.pdf")
    end
  end

  describe "#backup_name" do
    it "appends .bkp to the file name" do
      expect(file_info.backup_name).to eq("cuenta.pdf.bkp")
    end
  end

  describe "#dir" do
    it "returns the directory containing the file" do
      expect(file_info.dir).to eq(File.dirname(file_path))
    end
  end

  describe "#to_s" do
    it "returns the file name" do
      expect(file_info.to_s).to eq("cuenta.pdf")
    end
  end
end
