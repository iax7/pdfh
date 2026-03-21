# frozen_string_literal: true

RSpec.shared_context "with silent console" do
  let(:console) do
    instance_double(Pdfh::Console,
                    debug: nil,
                    info: nil,
                    headline: nil,
                    error_print: nil,
                    warn_print: nil,
                    ident_print: nil,
                    print_options: nil,
                    backtrace_print: nil,
                    verbose?: false)
  end

  before do
    Pdfh.logger = console
  end

  after do
    Pdfh.logger = nil
  end
end
