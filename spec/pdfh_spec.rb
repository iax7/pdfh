# frozen_string_literal: true

require 'pdfh/version'
require 'pdfh/settings'

RSpec.describe Pdfh do
  let(:settings_path) { File.expand_path('spec/fixtures/settings.yml') }
  let(:files) { ['EdoCta (1).pdf', 'dummy.pdf'] }
  let(:type_cta) do OpenStruct.new({
      name: 'Cuenta',
      re_file: Regexp.new('EdoCta( ?\(\d+\))?\.pdf'),
      re_date: Regexp.new('(\d{2})\/(?<m>\w+)\/(?<y>\d{4})')
    })
  end
  let(:document) do
    double(:document,
            type: 'Type',
            sub_type: 'Sub-Type',
            period: 'YYYY-MM',
            new_name: 'New_name.pdf',
            store_path: 'store_path/YYYY',
            companion_files: 'N/A',
            write_pdf: false)
  end

  it 'has a version number' do
    expect(Pdfh::VERSION).not_to be nil
  end

  it '#print_separator' do
    expect(STDOUT).to receive(:puts).and_return(nil)
    expect(subject.print_separator('testing')).to eq(nil)
  end

  it '#print_ident' do
    expect(STDOUT).to receive(:puts).and_return(nil)
    expect(subject.print_ident('field name', 'value', :blue)).to eq(nil)
  end

  context '#main' do
    before do
      expect(STDOUT).to receive(:puts).and_return(nil).at_least(:once)
    end

    it 'fails to load' do
      expect{ subject.main }.to raise_exception(SystemExit)
    end
    it 'loads' do
      expect(subject).to receive(:search_config_file).and_return(settings_path)
      expect(Dir).to receive(:[]).and_return(files)

      allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with('EdoCta (1).pdf').and_return(type_cta)
      allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with('dummy.pdf').and_return(nil)
      expect(Pdfh::Document).to receive(:new).with('EdoCta (1).pdf', anything).and_return(document)

      allow(subject).to receive(:print_separator).and_return(nil)
      allow(subject).to receive(:print_ident).and_return(nil)

      expect(subject.main).not_to eq(nil)
    end
  end

  context '#search_config_file' do
    it 'finds a configuration file' do
      expect(File).to receive(:file?).and_return(true)

      expect(subject.search_config_file).to end_with('pdfh/rspec.yml')
    end

    it 'fails to find a configuration file' do
      expect { subject.search_config_file }.to raise_error(StandardError)
    end
  end
end
