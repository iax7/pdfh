# frozen_string_literal: true

require 'pdfh/version'

RSpec.describe Pdfh do
  let(:settings) { File.expand_path('spec/fixtures/settings.yml') }

  it 'has a version number' do
    expect(Pdfh::VERSION).not_to be nil
  end

  it 'print_separator' do
    expect(subject.print_separator('testing')).to eq(nil)
  end

  it 'print_ident' do
    expect(subject.print_ident('field name', 'value', :blue)).to eq(nil)
  end

  context '#main' do
    it 'fails to load' do
      expect{ subject.main }.to raise_exception(SystemExit)
    end
    it 'loads' do
      expect(subject).to receive(:search_config_file).and_return(settings)
      allow(subject).to receive(:print_separator).and_return(nil)
      allow(subject).to receive(:print_ident).and_return(nil)
      expect(subject.main).not_to eq(nil)
    end
  end

  context '#search_config_file' do
    it 'finds a configuration file' do
      allow(File).to receive(:file?).and_return(true)

      expect(subject.search_config_file).to eq('/Users/iax/Dropbox/IFTTT/pdfh/rspec.yml')
    end

    it 'fails to find a configuration file' do
      expect { subject.search_config_file }.to raise_error(StandardError)
    end
  end
end
