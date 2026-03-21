# frozen_string_literal: true

RSpec.describe Pdfh::Services::DocumentMatcher do
  let(:file_path) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:mock_logger) { instance_double(Pdfh::Console, debug: nil) }
  before do
    @original_logger = Pdfh.logger
    Pdfh.logger = mock_logger
  end
  after do
    Pdfh.logger = @original_logger
  end
  describe "#match" do
    context "with named captures in regex" do
      let(:text) { "cuenta del 03/2024 al 04/2024" }
      let(:type) do
        instance_double(
          Pdfh::DocumentType,
          name: "Bank Statement",
          re_id: /cuenta/,
          re_date: %r{(?<m>\d{2})/(?<y>\d{4})}
        )
      end
      let(:matcher) { described_class.new([type]) }
      it "returns an array with one document when type and date match" do
        documents = matcher.match(file_path, text)
        expect(documents).to be_an(Array)
        expect(documents.size).to eq(1)
        expect(documents.first).to be_a(Pdfh::Document)
        expect(documents.first.text).to eq(text)
      end
      it "logs debug message about named captures" do
        expect(mock_logger).to receive(:debug).with(/Using.*named.*captures/)
        matcher.match(file_path, text)
      end
    end
    context "with positional captures in regex" do
      let(:text) { "invoice dated 05/2024" }
      let(:type) do
        instance_double(
          Pdfh::DocumentType,
          name: "Invoice",
          re_id: /invoice/,
          re_date: %r{(\d{2})/(\d{4})} # Sin named captures
        )
      end
      let(:matcher) { described_class.new([type]) }
      it "returns an array with one document when type and date match" do
        documents = matcher.match(file_path, text)
        expect(documents).to be_an(Array)
        expect(documents.size).to eq(1)
        expect(documents.first).to be_a(Pdfh::Document)
        expect(documents.first.text).to eq(text)
      end
      it "logs debug message about positional captures" do
        expect(mock_logger).to receive(:debug).with(/Using.*positional.*captures/)
        matcher.match(file_path, text)
      end
      it "converts positional captures to hash with m, y keys" do
        # El Document debería recibir un hash con 'm' y 'y'
        expect(Pdfh::Document).to receive(:new).with(
          file_path,
          type,
          text,
          hash_including("m" => "05", "y" => "2024")
        ).and_call_original
        matcher.match(file_path, text)
      end
    end
    context "with 3 positional captures (month, year, day)" do
      let(:text) { "document from 06/2024/15" }
      let(:type) do
        instance_double(
          Pdfh::DocumentType,
          name: "Full Date Doc",
          re_id: /document/,
          re_date: %r{(\d{2})/(\d{4})/(\d{2})} # month/year/day
        )
      end
      let(:matcher) { described_class.new([type]) }
      it "captures all three values" do
        expect(Pdfh::Document).to receive(:new).with(
          file_path,
          type,
          text,
          hash_including("m" => "06", "y" => "2024", "d" => "15")
        ).and_call_original
        matcher.match(file_path, text)
      end
    end
    context "when no date match" do
      let(:text) { "test document without date" }
      let(:type) do
        instance_double(
          Pdfh::DocumentType,
          name: "Test Doc",
          re_id: /test/,
          re_date: /\d{4}-\d{2}-\d{2}/
        )
      end
      let(:matcher) { described_class.new([type]) }
      it "returns empty array" do
        expect(matcher.match(file_path, text)).to eq([])
      end
      it "logs debug message about no date match" do
        expect(mock_logger).to receive(:debug).with(/No date match found/)
        matcher.match(file_path, text)
      end
    end
    context "when no type matches" do
      let(:text) { "random text" }
      let(:matcher) { described_class.new([]) }
      it "returns empty array" do
        expect(matcher.match(file_path, text)).to eq([])
      end
    end
    context "with multiple document types" do
      let(:text) { "cuenta Enero/2019" }
      let(:type1) do
        instance_double(
          Pdfh::DocumentType,
          name: "Type 1",
          re_id: /nomatch/,
          re_date: /\d+/
        )
      end
      let(:type2) do
        instance_double(
          Pdfh::DocumentType,
          name: "Type 2",
          re_id: /cuenta/,
          re_date: %r{(?<m>\w+)/(?<y>\d{4})}
        )
      end
      let(:matcher) { described_class.new([type1, type2]) }
      it "returns array with first matching type" do
        documents = matcher.match(file_path, text)
        expect(documents).to be_an(Array)
        expect(documents.size).to eq(1)
        expect(documents.first).to be_a(Pdfh::Document)
        expect(documents.first.type).to eq(type2)
      end
    end
  end
end
