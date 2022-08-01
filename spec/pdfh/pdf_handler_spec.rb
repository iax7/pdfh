# frozen_string_literal: true

RSpec.describe Pdfh::PdfHandler do
  subject(:main) { described_class.new(pdf_file, nil) }

  let(:pdf_file) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:dir_path) { "/tmp/2019/Edo Cuenta" }
  let(:full_path) { "/tmp/2019/Edo Cuenta/2019-01 Cuenta Enlace.pdf" }

  describe "#write_pdf" do
    before do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(main).to receive(:`).and_return(nil) # rubocop:disable RSpec/SubjectStub
    end

    it "runs Dry" do
      allow(Pdfh).to receive(:dry?).and_return(true).at_least(:once)

      expect(main.write_new_pdf(dir_path, full_path)).to be_nil
    end

    it "writes pdf successfully" do
      allow(File).to receive(:file?).with("/tmp/2019/Edo Cuenta/2019-01 Cuenta Enlace.pdf").and_return(true)
      main.write_new_pdf(dir_path, full_path)
    end

    it "fail to write pdf" do
      expect { main.write_new_pdf(dir_path, full_path) }.to raise_error(IOError)
    end
  end
end
