# frozen_string_literal: true

RSpec.describe Pdfh::Settings do
  let(:doc_type1) { instance_double(Pdfh::DocumentType, gid: "type1") }
  let(:doc_type2) { instance_double(Pdfh::DocumentType, gid: "type2") }
  let(:valid_config) do
    {
      lookup_dirs: %w[/tmp/dir1 /tmp/dir2],
      destination_base_path: "/tmp/destination",
      document_types: [
        { id: "type1", name: "Type 1", file_pattern: "pattern1_.*\\.pdf" },
        { id: "type2", name: "Type 2", file_pattern: "pattern2_.*\\.pdf" }
      ]
    }
  end

  before do
    # Mock file system operations
    allow(File).to receive(:directory?).and_return(true)
    allow(File).to receive(:expand_path).and_call_original

    # Mock Pdfh module methods
    allow(Pdfh).to receive(:debug)
    allow(Pdfh).to receive(:error_print)
    allow(Pdfh).to receive(:backtrace_print)
    allow(Pdfh).to receive(:verbose?)

    # Mock DocumentType initialization
    allow(Pdfh::DocumentType).to receive(:new)
      .with(valid_config[:document_types][0])
      .and_return(doc_type1)
    allow(Pdfh::DocumentType).to receive(:new)
      .with(valid_config[:document_types][1])
      .and_return(doc_type2)
  end

  describe "#initialize" do
    describe "lookup directories" do
      it "processes and expands lookup directories" do
        expect(File).to receive(:expand_path).with("/tmp/dir1").and_return("/expanded/dir1")
        expect(File).to receive(:expand_path).with("/tmp/dir2").and_return("/expanded/dir2")

        settings = described_class.new(valid_config)
        expect(settings.lookup_dirs).to eq(["/expanded/dir1", "/expanded/dir2"])
      end

      it "filters out non-existent directories" do
        allow(File).to receive(:directory?)
          .with("/expanded/dir1").and_return(true)
        allow(File).to receive(:directory?)
          .with("/expanded/dir2").and_return(false)
        allow(File).to receive(:expand_path)
          .with("/tmp/dir1").and_return("/expanded/dir1")
        allow(File).to receive(:expand_path)
          .with("/tmp/dir2").and_return("/expanded/dir2")

        settings = described_class.new(valid_config)
        expect(settings.lookup_dirs).to eq(["/expanded/dir1"])
      end

      it "raises error when no valid directories exist" do
        allow(File).to receive(:directory?).and_return(false)
        expect { described_class.new(valid_config) }
          .to raise_error(ArgumentError, "No valid Look up directories configured.")
      end
    end
  end

  describe "#document_type" do
    it "returns document type by id" do
      settings = described_class.new(valid_config)
      expect(settings.document_type("type1")).to eq(doc_type1)
      expect(settings.document_type("type2")).to eq(doc_type2)
    end

    it "returns nil for unknown type" do
      settings = described_class.new(valid_config)
      expect(settings.document_type("unknown")).to be_nil
    end
  end

  describe "#zip_types?" do
    it "returns false when no zip types configured" do
      settings = described_class.new(valid_config)
      expect(settings.zip_types?).to be false
    end

    it "returns true when zip types are configured" do
      config = valid_config.merge(zip_types: [{ id: "zip1" }])
      allow(Pdfh::Utils::DependencyValidator).to receive(:missing?)
        .with(:unzip).and_return(false)
      allow(Pdfh::ZipType).to receive(:new)
        .and_return(instance_double(Pdfh::ZipType))

      settings = described_class.new(config)
      expect(settings.zip_types?).to be true
    end
  end
end
