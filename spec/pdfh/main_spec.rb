# frozen_string_literal: true

RSpec.describe Pdfh::Main do
  include_context "with silent console"

  describe "#start" do
    let(:settings_path) { File.expand_path("spec/fixtures/settings.yml") }
    let(:files) { ["EdoCta (1).pdf", "dummy.pdf"] }
    let(:type_cta) do
      Pdfh::DocumentType.new({
                               name: "Cuenta",
                               re_file: Regexp.new('EdoCta( ?\(\d+\))?\.pdf'),
                               re_date: Regexp.new('(\d{2})\/(?<m>\w+)\/(?<y>\d{4})')
                             })
    end
    let(:document) do
      instance_double(Pdfh::Document,
                      type: "Type",
                      sub_type: "Sub-Type",
                      period: "YYYY-MM",
                      new_name: "New_name.pdf",
                      store_path: "store_path/YYYY",
                      companion_files: "N/A",
                      text: "",
                      print_cmd: "command -arg1 -arg2")
    end

    it "loads" do
      allow(Dir).to receive(:[]).and_return(files)

      allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with("EdoCta (1).pdf").and_return(type_cta)
      allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with("dummy.pdf").and_return(nil)
      allow(Pdfh::Document).to receive(:new).with("EdoCta (1).pdf", anything).and_return(document)

      expect(described_class.start).not_to be_nil
    end
  end
end