# frozen_string_literal: true

RSpec.describe Pdfh::Services::SettingsBuilder do
  subject(:builder) { described_class.new(program_name: "pdfh") }

  include_context "with silent console"

  describe "#call" do
    context "when settings exists" do
      let(:yaml_file) { File.expand_path("spec/fixtures/settings.yml") }

      before do
        allow(builder).to receive(:search_config_file).and_return(yaml_file)
      end

      it "returns a Settings instance" do
        expect(builder.call).to be_a(Pdfh::Settings)
      end
    end

    context "when settings file is not found" do
      let(:raw_config) do
        {
          lookup_dirs: [Dir.tmpdir],
          destination_base_path: Dir.tmpdir,
          document_types: [attributes_for(:document_type)]
        }
      end

      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:write)
        allow(builder).to receive(:search_config_file).and_return(nil)
        allow(builder).to receive(:create_settings_file).and_call_original
        allow(YAML).to receive(:load_file).and_return(raw_config)
      end

      it "creates a new settings file and returns Settings" do
        expect(builder.call).to be_a(Pdfh::Settings)
      end
    end

    context "when ENV var is set with valid path" do
      let(:yaml_file) { File.expand_path("spec/fixtures/settings.yml") }

      around do |example|
        old_val = ENV.fetch("PDFH_CONFIG_FILE", nil)
        ENV["PDFH_CONFIG_FILE"] = yaml_file
        example.run
        ENV["PDFH_CONFIG_FILE"] = old_val
      end

      it "uses the ENV var path" do
        expect(builder.call).to be_a(Pdfh::Settings)
      end
    end

    context "when ENV var is set with invalid path" do
      around do |example|
        old_val = ENV.fetch("PDFH_CONFIG_FILE", nil)
        ENV["PDFH_CONFIG_FILE"] = "/non/existent/file.yml"
        example.run
        ENV["PDFH_CONFIG_FILE"] = old_val
      end

      it "raises SettingsIOError" do
        expect { builder.call }.to raise_error(Pdfh::SettingsIOError, /not found/)
      end
    end
  end

  describe ".call" do
    it "creates instance and calls #call" do
      yaml_file = File.expand_path("spec/fixtures/settings.yml")
      allow_any_instance_of(described_class).to receive(:search_config_file).and_return(yaml_file)

      expect(described_class.call).to be_a(Pdfh::Settings)
    end
  end

  describe "SETTINGS_TEMPLATE" do
    it "defines default settings structure" do
      expect(described_class::SETTINGS_TEMPLATE).to include(
        :lookup_dirs,
        :destination_base_path,
        :document_types
      )
    end

    it "has frozen lookup_dirs array" do
      expect(described_class::SETTINGS_TEMPLATE[:lookup_dirs]).to be_frozen
    end

    it "has frozen document_types array" do
      expect(described_class::SETTINGS_TEMPLATE[:document_types]).to be_frozen
    end
  end

  describe "DOCUMENT_TYPE_TEMPLATE" do
    it "defines document type structure" do
      expect(described_class::DOCUMENT_TYPE_TEMPLATE).to include(
        :name,
        :re_id,
        :re_date,
        :store_path,
        :name_template
      )
    end

    it "is frozen" do
      expect(described_class::DOCUMENT_TYPE_TEMPLATE).to be_frozen
    end
  end

  describe "#search_config_file" do
    context "when config file exists in current directory with .yml extension" do
      let(:pwd_config) { File.join(Dir.pwd, "pdfh.yml") }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(pwd_config).and_return(true)
      end

      it "returns the config file path" do
        expect(builder.send(:search_config_file)).to eq(pwd_config)
      end

      it "does not check other locations" do
        builder.send(:search_config_file)
        expect(File).to have_received(:exist?).with(pwd_config)
      end
    end

    context "when config file exists in current directory with .yaml extension" do
      let(:pwd_config_yaml) { File.join(Dir.pwd, "pdfh.yaml") }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(pwd_config_yaml).and_return(true)
      end

      it "returns the .yaml config file when .yml does not exist" do
        expect(builder.send(:search_config_file)).to eq(pwd_config_yaml)
      end
    end

    context "with CONFIG_FILE_LOCATIONS" do
      it "includes current working directory as first location" do
        expect(described_class::CONFIG_FILE_LOCATIONS.first).to eq(Dir.pwd)
      end

      it "includes home directory as fallback location" do
        expect(described_class::CONFIG_FILE_LOCATIONS.last).to be_a(String)
      end

      it "has multiple locations for search priority" do
        expect(described_class::CONFIG_FILE_LOCATIONS.length).to be >= 2
      end
    end

    context "when config file exists in home directory" do
      let(:home_config) { File.join(File.expand_path("~"), "pdfh.yml") }

      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(home_config).and_return(true)
      end

      it "returns the config file from home directory" do
        expect(builder.send(:search_config_file)).to eq(home_config)
      end
    end

    context "when config file exists in multiple locations" do
      let(:pwd_config) { File.join(Dir.pwd, "pdfh.yml") }
      let(:home_config) { File.join(File.expand_path("~"), "pdfh.yml") }

      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(pwd_config).and_return(true)
        allow(File).to receive(:exist?).with(home_config).and_return(true)
      end

      it "returns the first found config file (current directory priority)" do
        expect(builder.send(:search_config_file)).to eq(pwd_config)
      end
    end

    context "when no config file exists" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "returns nil" do
        expect(builder.send(:search_config_file)).to be_nil
      end

      it "logs a warning message" do
        builder.send(:search_config_file)
        expect(Pdfh.logger).to have_received(:warn_print).with(/No configuration file was found/)
      end
    end
  end
end
