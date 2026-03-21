# frozen_string_literal: true

module Pdfh
  module Services
    # Loads or creates a default settings yaml file
    class SettingsBuilder
      CONFIG_FILE_LOCATIONS = [Dir.pwd, ENV.fetch("XDG_CONFIG_HOME", "~/.config"), "~"].freeze
      SUPPORTED_EXTENSIONS = %w[yml yaml].freeze
      ENV_VAR = "PDFH_CONFIG_FILE"

      DOCUMENT_TYPE_TEMPLATE = {
        name: "Example Name",
        re_id: "EXAMPLE MATCH",
        re_date: "(\d{2})/(?<m>\w+)/(?<y>\d{4})",
        store_path: "{YEAR}/sub folder",
        name_template: "{period} {original}"
      }.freeze

      SETTINGS_TEMPLATE = {
        lookup_dirs: ["~/Downloads"].freeze,
        destination_base_path: "~/Documents",
        document_types: [DOCUMENT_TYPE_TEMPLATE].freeze
      }.freeze

      # @param program_name [String, nil] Override for testing (defaults to PROGRAM_NAME)
      # @return [Settings]
      def self.call(program_name: nil)
        new(program_name: program_name).call
      end

      # @param program_name [String, nil]
      # @return [SettingsBuilder]
      def initialize(program_name: nil)
        @program_name = program_name || PROGRAM_NAME
      end

      # @return [Settings]
      def call
        config_file = find_config_file
        file_hash = YAML.load_file(config_file, symbolize_names: true)
        Pdfh.logger.debug "Loaded configuration file: #{config_file}"

        validated = Services::SettingsValidator.call(file_hash)
        Settings.new(**validated)
      end

      private

      # @return [String]
      def find_config_file
        env_config_file = ENV.fetch(ENV_VAR, nil)

        if env_config_file
          unless File.exist?(env_config_file)
            raise SettingsIOError,
                  "File path in #{ENV_VAR} not found: #{env_config_file}"
          end

          return env_config_file
        end

        search_config_file || create_settings_file
      end

      # @return [String]
      def config_file_name
        File.basename(@program_name, ".*")
      end

      # @return [String]
      def default_settings_name
        "#{config_file_name}.#{SUPPORTED_EXTENSIONS.first}"
      end

      # @return [String]
      def create_settings_file
        full_path = File.join(File.expand_path("~"), default_settings_name)
        return full_path if File.exist?(full_path) # double check

        File.write(full_path, stringify_keys(SETTINGS_TEMPLATE).to_yaml)
        Pdfh.logger.info "Default settings file was created: #{full_path.colorize(:green)}"

        full_path
      end

      # Recursively converts symbol keys to string keys for YAML serialization
      # @param value [Hash, Array, Object]
      # @return [Hash, Array, Object]
      def stringify_keys(value)
        case value
        when Hash then value.to_h { |k, v| [k.to_s, stringify_keys(v)] }
        when Array then value.map { |v| stringify_keys(v) }
        else value
        end
      end

      # Gets the first settings file found, or nil
      # @return [String, nil]
      def search_config_file
        CONFIG_FILE_LOCATIONS.each do |dir_string|
          dir = File.expand_path(dir_string)
          SUPPORTED_EXTENSIONS.each do |ext|
            path = File.join(dir, "#{config_file_name}.#{ext}")
            return path if File.exist?(path)
          end
        end

        Pdfh.logger.warn_print "No configuration file was found within paths: #{CONFIG_FILE_LOCATIONS.join(", ")}"
        nil
      end
    end
  end
end
