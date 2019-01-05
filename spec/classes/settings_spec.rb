# frozen_string_literal: true

require 'pdfh/settings'
require 'pdfh/utils'

RSpec.describe Pdfh::Settings do
  let(:settings) { File.expand_path('spec/fixtures/settings.yml') }
  subject { Pdfh::Settings.new(settings) }

  context '#initialize' do
    it 'correctly' do
      expect(subject.scrape_dirs).to be_a(Array)
      expect(subject.base_path).to be_a(String)
      expect(subject.document_types).to be_a(Array)
      expect(subject.document_types[0]).to be_a(OpenStruct)
    end
  end

  context '#match_doc_type' do
    it 'finds a match' do
      type = subject.match_doc_type('EdoCta (1).pdf')
      expect(type.name).to eq('Cuenta')
    end
    it 'fails to match' do
      type = subject.match_doc_type('this is not matched at all.pdf')
      expect(type).to be_nil
    end
  end
end
