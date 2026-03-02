# frozen_string_literal: true

RSpec.describe Pdfh::Services::DocumentManager do
  include_context "with silent console"

  let(:file_path) { File.expand_path("spec/fixtures/cuenta.pdf") }
  let(:base_path) { "/destination" }

  let(:document_type) do
    instance_double(
      Pdfh::DocumentType,
      name: "Cuenta"
    )
  end

  let(:file) { instance_double(File, path: file_path) }

  let(:document) do
    instance_double(
      Pdfh::Document,
      file: file,
      type: document_type,
      store_path: "2024/Cuenta",
      new_name: "2024-01 Cuenta.pdf",
      file_extension: ".pdf",
      file_name_only: "cuenta",
      file_name: "cuenta.pdf",
      home_dir: File.dirname(file_path),
      period: "2024-01"
    )
  end

  before do
    allow(Dir).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:glob).and_return([])
  end

  describe "#call" do
    context "when dry_run is true" do
      subject(:manager) { described_class.new(document, base_path: base_path, dry_run: true) }

      it "does not create directories" do
        allow(Dir).to receive(:exist?).and_return(false)
        expect(FileUtils).not_to receive(:mkdir_p)

        manager.call
      end

      it "does not copy PDF files" do
        expect(FileUtils).not_to receive(:cp)

        manager.call
      end

      it "does not move original to backup" do
        expect(FileUtils).not_to receive(:mv)

        manager.call
      end
    end

    context "when dry_run is false" do
      subject(:manager) { described_class.new(document, base_path: base_path, dry_run: false) }

      before do
        allow(FileUtils).to receive(:cp)
        allow(FileUtils).to receive(:mv)
      end

      it "creates destination directory if missing" do
        allow(Dir).to receive(:exist?).with("/destination/2024/Cuenta").and_return(false)
        expect(FileUtils).to receive(:mkdir_p).with("/destination/2024/Cuenta")

        manager.call
      end

      it "does not create directory if already exists" do
        allow(Dir).to receive(:exist?).with("/destination/2024/Cuenta").and_return(true)
        expect(FileUtils).not_to receive(:mkdir_p)

        manager.call
      end

      it "copies PDF to destination with correct path" do
        expect(FileUtils).to receive(:cp).with(
          file_path,
          "/destination/2024/Cuenta/2024-01 Cuenta.pdf",
          preserve: true
        )

        manager.call
      end

      it "moves original file to backup" do
        expect(FileUtils).to receive(:mv).with(file_path, "#{file_path}.bkp")

        manager.call
      end

      context "with companion files (normal case)" do
        before do
          allow(Dir).to receive(:glob)
            .with(File.join(File.dirname(file_path), "cuenta.*"))
            .and_return(["#{File.dirname(file_path)}/cuenta.xml", "#{File.dirname(file_path)}/cuenta.pdf"])
        end

        it "copies companion files with renamed extensions" do
          expect(FileUtils).to receive(:cp).with(
            file_path,
            "/destination/2024/Cuenta/2024-01 Cuenta.pdf",
            preserve: true
          )

          expect(FileUtils).to receive(:cp).with(
            "#{File.dirname(file_path)}/cuenta.xml",
            "/destination/2024/Cuenta/2024-01 Cuenta.xml",
            preserve: true
          )

          manager.call
        end

        it "does not copy PDF files as companion files" do
          # Should only copy the main PDF and the .xml file
          expect(FileUtils).to receive(:cp).exactly(2).times

          manager.call
        end
      end

      context "with companion files (PDF has _unlocked suffix)" do
        let(:unlocked_file_path) { File.expand_path("spec/fixtures/cuenta_unlocked.pdf") }
        let(:unlocked_document) do
          instance_double(
            Pdfh::Document,
            file: instance_double(File, path: unlocked_file_path),
            type: document_type,
            store_path: "2024/Cuenta",
            new_name: "2024-01 Cuenta.pdf",
            file_extension: ".pdf",
            file_name_only: "cuenta_unlocked",
            file_name: "cuenta_unlocked.pdf",
            home_dir: File.dirname(unlocked_file_path),
            period: "2024-01"
          )
        end

        before do
          # When searching for companion files, the suffix should be removed
          # So we search for "cuenta.*" not "cuenta_unlocked.*"
          allow(Dir).to receive(:glob)
            .with(File.join(File.dirname(unlocked_file_path), "cuenta.*"))
            .and_return([
                          "#{File.dirname(unlocked_file_path)}/cuenta.xml",
                          "#{File.dirname(unlocked_file_path)}/cuenta.pdf"
                        ])
        end

        it "searches for companion files without the _unlocked suffix" do
          manager_with_unlocked = described_class.new(unlocked_document, base_path: base_path, dry_run: false)

          allow(FileUtils).to receive(:cp)
          allow(FileUtils).to receive(:mv)

          expect(Dir).to receive(:glob)
            .with(File.join(File.dirname(unlocked_file_path), "cuenta.*"))

          manager_with_unlocked.call
        end

        it "copies companion files found by the suffix-stripped search" do
          manager_with_unlocked = described_class.new(unlocked_document, base_path: base_path, dry_run: false)

          expect(FileUtils).to receive(:cp).with(
            unlocked_file_path,
            "/destination/2024/Cuenta/2024-01 Cuenta.pdf",
            preserve: true
          )

          expect(FileUtils).to receive(:cp).with(
            "#{File.dirname(unlocked_file_path)}/cuenta.xml",
            "/destination/2024/Cuenta/2024-01 Cuenta.xml",
            preserve: true
          )

          manager_with_unlocked.call
        end

        it "correctly renames companion files when PDF has _unlocked suffix" do
          manager_with_unlocked = described_class.new(unlocked_document, base_path: base_path, dry_run: false)

          # The companion file should NOT have the _unlocked suffix in its name
          expect(FileUtils).to receive(:cp).exactly(2).times

          manager_with_unlocked.call
        end
      end
    end
  end
end
