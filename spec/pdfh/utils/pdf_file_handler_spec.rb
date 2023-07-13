# frozen_string_literal: true

RSpec.describe Pdfh::PdfFileHandler do
  subject(:main) { described_class.new(pdf_file, nil) }

  include_context "with silent console"

  let(:pdf_file) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:dir_path) { "/tmp/2019/Edo Cuenta" }
  let(:full_path) { "/tmp/2019/Edo Cuenta/2019-01 Cuenta Enlace.pdf" }

  describe "#process_document" do
    before do
      allow(Pdfh).to receive(:dry?).and_return(true).at_least(:once)
      allow(Dir).to receive(:exist?).and_return(true)
      allow(main).to receive(:`).and_return(nil) # rubocop:disable RSpec/SubjectStub
    end

    it "proccess it" do
      expect(main.process_document(dir_path)).to be_nil
    end
  end
end
