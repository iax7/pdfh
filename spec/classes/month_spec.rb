# frozen_string_literal: true

require 'pdfh/month'

RSpec.describe Pdfh::Month do
  subject { described_class }

  context '#normalize' do
    it 'param is a number' do
      month = subject.normalize('02')
      expect(month).to eq(2)
    end
    it 'param is a 3 digit month "feb"' do
      month = subject.normalize('feb')
      expect(month).to eq(2)
    end
    it 'param is spanish month "febrero"' do
      month = subject.normalize('febrero')
      expect(month).to eq(2)
    end
    it 'param is a no existing month number' do
      month = subject.normalize('15')
      expect(month).to be_nil
    end
    it 'param is a no existing spanish month' do
      month = subject.normalize('abcdef')
      expect(month).to be_nil
    end
  end
end
