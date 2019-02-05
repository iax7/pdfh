
# frozen_string_literal: true

require 'ostruct'
require 'pdfh/document'

RSpec.describe Pdfh::PdfHandler do
  let(:pdf_file) { File.expand_path('spec/fixtures/cuenta.pdf') }
  let(:dir_path) { '/tmp/2019/Edo Cuenta' }
  let(:full_path) { '/tmp/2019/Edo Cuenta/2019-01 Cuenta Enlace.pdf' }
  subject { described_class.new(pdf_file, nil) }

  context '#write_pdf' do
    it 'runs Dry' do
      expect(Dir).to receive(:exist?).and_return(true)
      expect(Pdfh::Dry).to receive(:active?).and_return(true).at_least(:once)

      expect(subject.write_pdf(dir_path, full_path)).to eq(nil)
    end

    it 'writes pdf successfuly' do
      expect(Dir).to receive(:exist?).and_return(true)
      expect(subject).to receive(:`).and_return(nil)
      expect(File).to receive(:file?).with('/tmp/2019/Edo Cuenta/2019-01 Cuenta Enlace.pdf').and_return(true)
      subject.write_pdf(dir_path, full_path)
    end

    it 'fail to write pdf' do
      expect(Dir).to receive(:exist?).and_return(true)
      expect(subject).to receive(:`).and_return(nil)

      expect{ subject.write_pdf(dir_path, full_path) }.to raise_error(IOError)
    end
  end
end
