# frozen_string_literal: true

module Pdfh
  # Loads or creates a default settings yaml file
  class SettingsBuilder
    CONFIG_FILE_LOCATIONS = [Dir.pwd, ENV.fetch("XDG_CONFIG_HOME", "~/.config"), "~"].freeze
    SUPPORTED_EXTENSIONS = %w[yml yaml].freeze
    ENV_VAR = "PDFH_CONFIG_FILE"

    class << self
      # @return [Pdfh::Settings]
      def build
        env_config_file = ENV.fetch(ENV_VAR, nil)
        raise "File path in #{ENV_VAR} not found" if env_config_file && !File.exist?(env_config_file)

        config_file = env_config_file || search_config_file
        file_hash = YAML.load_file(config_file, symbolize_names: true)
        Pdfh.debug "Loaded configuration file: #{config_file}"

        Settings.new(file_hash)
      end

      private

      # @return [String]
      def config_file_name
        File.basename($PROGRAM_NAME)
      end

      # @return [String (frozen)]
      def default_settings_name
        "#{config_file_name}.#{SUPPORTED_EXTENSIONS.first}"
      end

      # @return [String]
      def create_settings_file
        full_path = File.join(File.expand_path("~"), default_settings_name)
        return if File.exist?(full_path) # double check

        File.write(full_path, Pdfh::SETTINGS_TEMPLATE.to_yaml)
        Pdfh.info "Default settings file was created: #{full_path.colorize(:green)}"

        full_path
      end

      # Gets the first settings file found, or creates a new one
      # @return [String]
      def search_config_file
        CONFIG_FILE_LOCATIONS.each do |dir_string|
          dir = File.expand_path(dir_string)
          SUPPORTED_EXTENSIONS.each do |ext|
            path = File.join(dir, "#{config_file_name}.#{ext}")
            return path if File.exist?(path)
          end
        end

        Pdfh.warn_print "No configuration file was found within paths: #{CONFIG_FILE_LOCATIONS.join(", ")}"
        create_settings_file
      end
    end
  end
end
