# frozen_string_literal: true

RSpec.describe Pdfh::Services::SettingsValidator do
  include_context "with silent console"
  let(:lookup_dirs) { [Dir.tmpdir] }
  let(:destination_base_path) { Dir.tmpdir }
  let(:document_types) { [attributes_for(:document_type, name: "Invoice", store_path: "{year}/Invoices")] }
  let(:config_data) do
    {
      lookup_dirs: lookup_dirs,
      destination_base_path: destination_base_path,
      document_types: document_types
    }
  end
  subject(:result) { described_class.call(config_data) }
  describe ".call" do
    context "with valid configuration" do
      it "returns a hash with validated attributes" do
        expect(result).to be_a(Hash)
        expect(result).to include(:lookup_dirs, :base_path, :document_types)
      end
      it "expands and returns lookup directories" do
        expect(result[:lookup_dirs]).to all(start_with("/"))
      end
      it "expands and returns base path" do
        expect(result[:base_path]).to start_with("/")
      end
      it "returns document_types as a hash keyed by gid" do
        expect(result[:document_types]).to be_a(Hash)
        expect(result[:document_types].values).to all(be_a(Pdfh::DocumentType))
      end
    end
    context "with invalid lookup_dirs" do
      let(:lookup_dirs) { ["/non/existent/path"] }
      it "raises ArgumentError when no valid directories exist" do
        expect { result }.to raise_error(ArgumentError, /No valid lookup_dirs/)
      end
    end
    context "with empty lookup_dirs" do
      let(:lookup_dirs) { [] }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /No valid lookup_dirs/)
      end
    end
    context "with nil lookup_dirs" do
      let(:lookup_dirs) { nil }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /Look up directories are not configured/)
      end
    end
    context "with non-string lookup_dirs" do
      let(:lookup_dirs) { [Dir.tmpdir, 123] }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /Look up directories must be an array of strings/)
      end
    end
    context "with mixed valid and invalid lookup_dirs" do
      let(:lookup_dirs) { [Dir.tmpdir, "asdadaas"] }
      it "logs warning message for invalid directory" do
        expect(console).to receive(:warn_print).at_least(:once)
        result
      end
      it "succeeds with at least one valid directory" do
        expect { result }.not_to raise_error
      end
      it "only includes valid directories" do
        expect(result[:lookup_dirs]).to contain_exactly(Dir.tmpdir)
      end
    end
    context "with nil destination_base_path" do
      let(:destination_base_path) { nil }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /destination_base_path is invalid or does not exist/)
      end
    end
    context "with non-existent destination_base_path" do
      let(:destination_base_path) { "/non/existent/destination" }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /destination_base_path is invalid or does not exist/)
      end
    end
    context "with empty destination_base_path" do
      let(:destination_base_path) { "" }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /destination_base_path is invalid or does not exist/)
      end
    end
    context "with non-string destination_base_path" do
      let(:destination_base_path) { 123 }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /destination_base_path is invalid or does not exist/)
      end
    end
    context "with nil document_types" do
      let(:document_types) { nil }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /Document types are not configured/)
      end
    end
    context "with empty document_types" do
      let(:document_types) { [] }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /No valid document types configured/)
      end
    end
    context "with non-hash document_types" do
      let(:document_types) { [123, "string", :symbol] }
      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /Document types must be an array of hashes/)
      end
    end
    context "with tilde paths" do
      let(:lookup_dirs) { ["~/Downloads"] }
      let(:destination_base_path) { "~/Documents" }
      before do
        allow(File).to receive(:directory?).and_return(true)
      end
      it "expands tilde paths" do
        expect(result[:lookup_dirs].first).not_to include("~")
        expect(result[:base_path]).not_to include("~")
      end
    end
    context "with valid document types" do
      it "builds document types" do
        expect(result[:document_types].values).to have_attributes(size: 1)
      end
      it "creates DocumentType instances" do
        expect(result[:document_types].values.first).to be_a(Pdfh::DocumentType)
      end
    end
    context "with invalid document types" do
      let(:document_types) do
        [
          {
            name: "Invalid"
            # Missing required fields
          }
        ]
      end
      it "logs info message and raises ArgumentError" do
        expect(console).to receive(:info).with(anything)
        expect { result }.to raise_error(ArgumentError, /No valid document types configured/)
      end
    end
    context "with mixed valid and invalid document types" do
      let(:document_types) do
        [
          attributes_for(:document_type, name: "Valid Invoice", store_path: "{year}/Invoices"),
          {
            name: "Invalid Type"
            # Missing required fields
          }
        ]
      end
      it "includes only valid document types" do
        allow(console).to receive(:info)
        doc_types = result[:document_types].values
        expect(doc_types.size).to eq(1)
        expect(doc_types.first.name).to eq("Valid Invoice")
      end
    end
  end
end
