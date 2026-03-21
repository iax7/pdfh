# frozen_string_literal: true

RSpec.describe Pdfh::Services::DirectoryScanner do
  let(:lookup_dirs) { ["/tmp/dir1", "/tmp/dir2"] }

  subject(:scanner) { described_class.new(lookup_dirs) }

  it "scans lookup dirs and returns matched documents" do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with("/tmp/dir1/*.pdf").and_return(["/tmp/dir1/a.pdf"])
    allow(Dir).to receive(:glob).with("/tmp/dir2/*.pdf").and_return(["/tmp/dir2/b.pdf"])

    result = scanner.scan

    expect(result).to eq(["/tmp/dir1/a.pdf", "/tmp/dir2/b.pdf"])
  end
end
