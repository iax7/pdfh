# frozen_string_literal: true

RSpec.describe Pdfh::Main do
  include_context "with silent console"

  describe "#start" do
    before do
      allow($stdout).to receive(:puts).and_return(nil)
    end

    context "without provided files" do
      let(:settings_path) { File.expand_path("spec/fixtures/settings.yml") }
      let(:files) { ["EdoCta (1).pdf", "dummy.pdf"] }
      let(:type_cta) { build(:document_type) }
      let(:document) { build(:document) }

      it "loads" do
        allow(Dir).to receive(:[]).and_return(files)

        allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with("EdoCta (1).pdf").and_return(type_cta)
        allow_any_instance_of(Pdfh::Settings).to receive(:match_doc_type).with("dummy.pdf").and_return(nil)
        allow(Pdfh::Document).to receive(:new).with("EdoCta (1).pdf", anything).and_return(document)

        expect(described_class.start).not_to be_nil
      end
    end

    context "with provided files" do
      let(:options) { attributes_for(:options, :file_mode) }

      it "loads" do
        allow(Pdfh::OptParser).to receive(:parse_argv).and_return(options)
        expect(described_class.start).to eq(options[:files])
      end
    end
  end
end
