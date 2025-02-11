# frozen_string_literal: true

RSpec.describe Pdfh::Document do
  subject(:main) { described_class.new(doc_file, doc_type, text) }

  include_context "with silent console"

  let(:doc_file) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:doc_type) { build(:document_type) }
  let(:text) { "del 06/Enero/2019 al 05/Febrero/2019\nCuenta Tipo: Enlace" }

  describe "#initialize" do
    it "correctly" do
      expect(main.sub_type).to eq("Enlace")
    end
  end

  describe "#print_info" do
    it "correctly" do
      expect(main.print_info).to be_nil
    end
  end

  it "#file_name_only" do
    expect(main.file_name_only).to eq("cuenta")
  end

  it "#file_name" do
    expect(main.file_name).to eq("cuenta.pdf")
  end

  it "#backup_name" do
    expect(main.backup_name).to eq("cuenta.pdf.bkp")
  end

  it "#store_path" do
    expect(main.store_path).to eq("2019/Edo Cuenta")
  end

  it "#to_s" do
    expect(main.to_s).to be_a(String)
  end

  it "#new_name" do
    expect(main.new_name).to eq("2019-01 Cuenta Enlace.pdf")
  end

  it "ReDateError changes messages" do
    msg = "Custom error"
    error = Pdfh::ReDateError.new(msg)

    expect { raise error }.to raise_error(Pdfh::ReDateError, msg)
  end

  describe "#companion_files" do
    it "has files" do
      res = main.companion_files(join: true)

      expect(res).to eq("cuenta.xml")
    end

    it "has no files" do
      main.instance_variable_set(:@companion, [])
      res = main.companion_files(join: true)

      expect(res).to eq("N/A")
    end
  end

  describe "#match_data (private method)" do
    let(:text) { "al 27 de Septiembre de 2018 " }

    context "when regular expression has unnamed params" do
      let(:unnamed_re) { /al \d{2} de (\w+) de (\d{4})/ }
      let(:doc_type) { build(:document_type, re_date: unnamed_re) }

      it "does not have named captures" do
        expect(unnamed_re.named_captures).to be_empty
      end

      it "returns the correct data" do
        result = main.instance_eval { match_data }
        expect(result).to eq(%w[septiembre 2018])
      end
    end

    context "when Regular expression has named params" do
      let(:named_re) { /al (?<d>\d{2}) de (?<m>\w+) de (?<y>\d{4})/ }
      let(:doc_type) { build(:document_type, re_date: named_re) }

      it "does have named captures" do
        expect(named_re.named_captures).not_to be_empty
      end

      it "returns the correct data" do
        result = main.instance_eval { match_data }
        expect(result).to eq(%w[septiembre 2018 27])
      end
    end
  end
end
