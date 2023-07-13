# frozen_string_literal: true

RSpec.describe Pdfh::Console do
  subject(:main) { described_class.new(true) }

  before { allow($stdout).to receive(:puts).and_return(nil) }

  it "#debug" do
    expect(main.debug("testing")).to be_nil
  end

  it "#info" do
    expect(main.info("testing")).to be_nil
  end

  it "#headline" do
    expect(main.headline("testing")).to be_nil
  end

  it "#error_print" do
    error = StandardError.new("Testing")
    expect { main.error_print(error) }.to raise_error SystemExit
  end

  it "#warn_print" do
    expect(main.warn_print("testing")).to be_nil
  end

  it "#ident_print" do
    expect(main.ident_print("field name", "value", color: :blue)).to be_nil
  end

  it "#print_options" do
    options = { dry: false, verbose: true, empty: nil, type: "type", sub_type: :sub, files: [] }
    expect(main.print_options(options)).to be_nil
  end
end
