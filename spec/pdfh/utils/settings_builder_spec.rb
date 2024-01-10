# frozen_string_literal: true

RSpec.describe Pdfh::SettingsBuilder do
  subject { described_class.build }

  include_context "with silent console"

  describe "#build" do
    context "when settings exists" do
      let(:yaml_file) { File.expand_path("spec/fixtures/settings.yml") }

      before do
        allow(described_class).to receive(:search_config_file).and_return(yaml_file)
      end

      it { is_expected.to be_a(Pdfh::Settings) }
    end

    context "when settings file is not found" do
      before do
        allow(File).to receive_messages(exist?: false, write: nil) # prevents writing default_yml
        allow(YAML).to receive(:load_file).and_return(attributes_for(:settings))
      end

      it { is_expected.to be_a(Pdfh::Settings) }
    end
  end
end
