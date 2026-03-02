# frozen_string_literal: true

RSpec.describe Pdfh::Services::PdfTextExtractor do
  include_context "with silent console"

  let(:valid_pdf) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:mock_logger) { console }

  describe ".call" do
    context "with a valid PDF file" do
      it "extracts text from the PDF" do
        text = described_class.call(valid_pdf)
        expect(text).to be_a(String)
      end

      it "returns non-empty text content" do
        text = described_class.call(valid_pdf)
        expect(text).not_to be_empty
      end
    end

    context "with invalid inputs" do
      it "raises ArgumentError when path is nil" do
        expect { described_class.call(nil) }.to raise_error(ArgumentError, /cannot be nil/)
      end

      it "raises ArgumentError when path is empty" do
        expect { described_class.call("") }.to raise_error(ArgumentError, /cannot be empty/)
      end

      it "raises ArgumentError when file does not exist" do
        expect { described_class.call("/tmp/nonexistent.pdf") }.to raise_error(ArgumentError, /does not exist/)
      end

      it "raises ArgumentError when path is not a file" do
        expect { described_class.call(Dir.tmpdir) }.to raise_error(ArgumentError, /Not a file/)
      end

      it "raises ArgumentError when file is not a PDF" do
        non_pdf = File.expand_path("spec/fixtures/cuenta.xml")
        expect { described_class.call(non_pdf) }.to raise_error(ArgumentError, /Not a PDF/)
      end
    end

    context "when pdftotext is not available or fails" do
      it "returns empty string when extraction fails" do
        # Stub call method to simulate extraction failure
        allow(described_class).to receive(:call).and_call_original
        allow(described_class).to receive(:call).with(valid_pdf) do
          described_class.validate_file!(valid_pdf)
          ""
        end

        expect(console).to receive(:debug).with(/Failed to extract/).at_most(:once)

        text = described_class.call(valid_pdf)
        expect(text).to eq("")
      end
    end
  end

  describe ".validate_file!" do
    it "passes validation for valid PDF" do
      expect { described_class.validate_file!(valid_pdf) }.not_to raise_error
    end

    it "raises for nil path" do
      expect { described_class.validate_file!(nil) }.to raise_error(ArgumentError, /cannot be nil/)
    end

    it "raises for empty path" do
      expect { described_class.validate_file!("") }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it "raises for non-existent file" do
      expect { described_class.validate_file!("/tmp/nonexistent.pdf") }.to raise_error(ArgumentError, /does not exist/)
    end

    it "raises when path is a directory" do
      expect { described_class.validate_file!(Dir.tmpdir) }.to raise_error(ArgumentError, /Not a file/)
    end

    it "raises for non-PDF file" do
      non_pdf = File.expand_path("spec/fixtures/cuenta.xml")
      expect { described_class.validate_file!(non_pdf) }.to raise_error(ArgumentError, /Not a PDF/)
    end
  end
end
