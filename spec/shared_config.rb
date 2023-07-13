# frozen_string_literal: true

RSpec.shared_context "with silent console" do
  let(:console) do
    instance_double(Pdfh::Console, debug: true,
                                   info: true,
                                   headline: true,
                                   error_print: true,
                                   warn_print: true,
                                   ident_print: true,
                                   print_options: true)
  end

  let(:options) do
    build(:options)
  end

  before do
    Pdfh.instance_variable_set(:@console, console)
    Pdfh.instance_variable_set(:@options, options)
  end
end
