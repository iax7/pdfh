# frozen_string_literal: true

RSpec.describe Pdfh::Settings do
  subject(:main) { described_class.new(yaml_file) }

  let(:yaml_file) { File.expand_path("spec/fixtures/settings.yml") }

  describe "#initialize" do
    it { expect(main.lookup_dirs).to be_a(Array) }
    it { expect(main.base_path).to be_a(String) }
    it { expect(main.document_types).to be_a(Array) }
    it { expect(main.document_types.first).to be_a(Pdfh::DocumentType) }
  end
end
