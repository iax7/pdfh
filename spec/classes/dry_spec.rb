# frozen_string_literal: true

require "pdfh/utils"

RSpec.describe Pdfh::Dry do
  it "is active" do
    described_class.active = true
    expect(described_class).to be_active
  end
  it "is disabled" do
    described_class.active = false
    expect(described_class).not_to be_active
  end
end
