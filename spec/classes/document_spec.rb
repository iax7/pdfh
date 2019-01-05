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
      name_template: '{period} Enlace Cuenta'
    }
    OpenStruct.new(hash)
  end

  subject { Pdfh::Document.new(cuenta_file, cuenta_type) }

  context '#initialize' do
    it 'correctly' do
      expect(subject.sub_type).to eq('N/A')
      expect(subject.year).to eq(2019)
      expect(subject.month).to eq(1)
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

  it '#store_path' do
    expect(subject.store_path).to eq('2019/Edo Cuenta')
  end

  it '#to_s' do
    expect(subject.to_s).to be_a(String)
  end

  it '#new_name' do
    expect(subject.new_name).to eq('2019-01 Enlace Cuenta.pdf')
  end

  context '#companion_files' do
    it 'has files' do
      expect(subject).to receive(:find_companion_files).and_return(['cuenta.xml'])
      res = subject.companion_files(join: true)

      expect(res).to eq('cuenta.xml')
    end
    it 'has no files' do
      res = subject.companion_files(join: true)

      expect(res).to eq('N/A')
    end
  end

  it '#write_pdf' do
    expect(Dir).to receive(:exist?).and_return(true)
    expect(Pdfh::Dry).to receive(:active?).and_return(true)

    expect(subject.write_pdf('/')).to eq(nil)
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
    end
    it 'has offset +1 | from 2019-12 -> 2020-01' do
      subject.instance_variable_set(:@month_offset, 1)
      subject.instance_variable_set(:@month, '12')

      expect(subject.month).to eq(1)
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
end
