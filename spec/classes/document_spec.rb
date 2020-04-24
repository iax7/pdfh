# frozen_string_literal: true

require 'ostruct'
require 'pdfh/document'

RSpec.describe Pdfh::Document do
  let(:cuenta_file) { File.expand_path('spec/fixtures/cuenta.pdf') }
  let(:cuenta_type) do
    hash = {
      name: 'Cuenta',
      re_file: /cuenta\.pdf/,
      re_date: /\d{2}\/(?<m>\w+)\/(?<y>\d{4})/,
      pwd: nil,
      store_path: '{YEAR}/Edo Cuenta',
      name_template: '{period} {type} {subtype}',
      sub_types: [{ 'name' => 'Enlace' }]
    }
    OpenStruct.new(hash)
  end

  subject { described_class.new(cuenta_file, cuenta_type) }

  context '#initialize' do
    it 'correctly' do
      expect(subject.sub_type).to eq('Enlace')
      expect(subject.year).to eq(2019)
      expect(subject.month).to eq(1)
    end
    it 'fails when does not exists' do
      expect { described_class.new('/does_not_exists.pdf', cuenta_type) }.to raise_error(IOError)
    end
  end

  it '#file_name_only' do
    expect(subject.file_name_only).to eq('cuenta')
  end

  it '#period returns year-month' do
    expect(subject).to receive(:month).and_return(11)
    expect(subject).to receive(:year).and_return(2019)

    expect(subject.period).to eq('2019-11')
  end

  it '#file_name' do
    expect(subject.file_name).to eq('cuenta.pdf')
  end

  it '#backup_name' do
    expect(subject.backup_name).to eq('cuenta.pdf.bkp')
  end

  it '#store_path' do
    expect(subject.store_path).to eq('2019/Edo Cuenta')
  end

  it '#to_s' do
    expect(subject.to_s).to be_a(String)
  end

  it '#new_name' do
    expect(subject.new_name).to eq('2019-01 Cuenta Enlace.pdf')
  end

  it 'ReDateError changes messages' do
    msg = 'Custom error'
    error = Pdfh::ReDateError.new(msg)

    expect { raise error }.to raise_error(Pdfh::ReDateError, msg)
  end

  context '#companion_files' do
    it 'has files' do
      res = subject.companion_files(join: true)

      expect(res).to eq('cuenta.xml')
    end
    it 'has no files' do
      subject.instance_variable_set(:@companion, [])
      res = subject.companion_files(join: true)

      expect(res).to eq('N/A')
    end
  end

  context '#write_pdf' do
    it 'writes pdf successfuly' do
      pdf_handler = double(:pdf_doc, write_pdf: true)
      subject.instance_variable_set(:@pdf_doc, pdf_handler)

      expect(File).to receive(:rename).and_return(true)
      expect(FileUtils).to receive(:cp).and_return(true)
      subject.write_pdf('/tmp')
    end
  end

  context '#month' do
    it 'from noviembre returns 11' do
      subject.instance_variable_set(:@month, 'noviembre')
      expect(subject.month).to eq(11)
    end
    it 'from nov returns 11' do
      subject.instance_variable_set(:@month, 'nov')
      expect(subject.month).to eq(11)
    end
    it 'from 11 returns 11' do
      subject.instance_variable_set(:@month, '11')
      expect(subject.month).to eq(11)
    end
    it 'from 11 number returns 11' do
      subject.instance_variable_set(:@month, 11)
      expect(subject.month).to eq(11)
    end
    it 'has offset -1 | from 2019-01 -> 2018-12' do
      subject.instance_variable_set(:@month_offset, -1)
      subject.instance_variable_set(:@month, '1')

      expect(subject.month).to eq(12)
      expect(subject.year).to eq(2018)
    end
    it 'has offset +1 | from 2019-12 -> 2020-01' do
      subject.instance_variable_set(:@month_offset, 1)
      subject.instance_variable_set(:@month, '12')

      expect(subject.month).to eq(1)
      expect(subject.year).to eq(2020)
    end
  end

  context '#year' do
    it 'from 19 with year offset 1' do
      subject.instance_variable_set(:@year, '19')
      subject.instance_variable_set(:@year_offset, 1)

      expect(subject.year).to eq(2020)
    end
    it 'from 19 returns 2019' do
      subject.instance_variable_set(:@year, '19')

      expect(subject.year).to eq(2019)
    end
  end

  context '#print_cmd' do
    it 'returns nil if string empty' do
      expect(subject.print_cmd).to eq('N/A')
    end
    it 'returns string if not empty' do
      subject.type.print_cmd = 'command'
      expect(subject.print_cmd).to start_with('command')
    end
  end

  context '#match_data (private method)' do
    let(:text) { 'al 27 de Septiembre de 2018 ' }
    let(:unamed_re) { /al \d{2} de (\w+) de (\d{4})/ }
    let(:named_re) { /al (?<d>\d{2}) de (?<m>\w+) de (?<y>\d{4})/ }

    before do
      subject.instance_variable_set(:@text, text)
    end

    it 'Regular expresion has unnamed params' do
      type = double(:type, re_date: unamed_re)
      subject.instance_variable_set(:@type, type)

      expect(unamed_re.named_captures).to be_empty

      result = subject.instance_eval { match_data }
      expect(result).to eq(["septiembre", "2018"])
    end

    it 'Regular expresion has named params' do
      type = double(:type, re_date: named_re)
      subject.instance_variable_set(:@type, type)

      expect(named_re.named_captures).not_to be_empty

      result = subject.instance_eval { match_data }
      expect(result).to eq(["septiembre", "2018", "27"])
    end
  end
end
