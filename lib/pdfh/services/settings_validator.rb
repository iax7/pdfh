# frozen_string_literal: true

module Pdfh
  module Services
    # Validates and processes raw configuration data from YAML into clean,
    # validated attributes ready for Settings construction.
    class SettingsValidator
      # @param config_data [Hash] Raw configuration hash from YAML
      # @return [Hash] Validated and processed attributes for Settings
      # @raise [ArgumentError] if configuration is invalid
      def self.call(config_data)
        new(config_data).call
      end

      # @param config_data [Hash]
      # @return [Self]
      def initialize(config_data)
        @config_data = config_data
      end

      # @return [Hash{Symbol => Object}] with keys :lookup_dirs, :base_path, :document_types
      def call
        {
          lookup_dirs: process_lookup_dirs(@config_data[:lookup_dirs]),
          base_path: process_destination_base(@config_data[:destination_base_path]),
          document_types: build_doc_types(@config_data[:document_types])
        }
      end

      private

      # Expands and validates a directory. Returns nil if invalid.
      # @param dir [String, nil]
      # @return [String, nil]
      def expand_directory(dir)
        return nil unless dir.is_a?(String) && !dir.strip.empty?

        expanded = File.expand_path(dir)
        File.directory?(expanded) ? expanded : nil
      end

      # Same as expand_directory but raises on failure.
      # @param dir [String, nil]
      # @param label [String] used in the error message
      # @return [String]
      # @raise [ArgumentError]
      def expand_directory!(dir, label:)
        expand_directory(dir) || raise(ArgumentError, "#{label} is invalid or does not exist: #{dir.inspect}")
      end

      # @param lookup_dirs_list [Array<String>]
      # @return [Array<String>]
      def process_lookup_dirs(lookup_dirs_list)
        validate_lookup_dirs_type(lookup_dirs_list)

        dirs = lookup_dirs_list.filter_map do |dir|
          expanded = expand_directory(dir)
          Pdfh.logger.warn_print "lookup_dirs: #{dir.inspect} does not exist, skipping." unless expanded
          expanded
        end
        raise ArgumentError, "No valid lookup_dirs configured." if dirs.empty?

        Pdfh.logger.debug "Configured Look up directories:"
        dirs.each.with_index(1) { |dir, idx| Pdfh.logger.debug "  #{idx}. #{dir}" }
        Pdfh.logger.debug

        dirs
      end

      # @param lookup_dirs_list [Array, nil]
      # @return [void]
      # @raise [ArgumentError] if lookup_dirs_list is invalid
      def validate_lookup_dirs_type(lookup_dirs_list)
        raise ArgumentError, "Look up directories are not configured." if lookup_dirs_list.nil?
        raise ArgumentError, "Look up directories must be an array of strings." unless lookup_dirs_list.is_a?(Array)
        return if lookup_dirs_list.all?(String)

        raise ArgumentError, "Look up directories must be an array of strings."
      end

      # @param dir [String, nil]
      # @return [String]
      def process_destination_base(dir)
        expand_directory!(dir, label: "destination_base_path")
      end

      # @param doc_types [Array<Hash>]
      # @return [Hash{String => DocumentType}]
      def build_doc_types(doc_types)
        validate_doc_types_type(doc_types)
        doc_types = parse_doc_types(doc_types)
        raise ArgumentError, "No valid document types configured." if doc_types.empty?

        doc_types
      end

      # @param doc_types [Array, nil]
      # @return [void]
      # @raise [ArgumentError] if doc_types is invalid
      def validate_doc_types_type(doc_types)
        raise ArgumentError, "Document types are not configured." if doc_types.nil?
        raise ArgumentError, "Document types must be an array." unless doc_types.is_a?(Array)
        raise ArgumentError, "Document types must be an array of hashes." unless doc_types.all?(Hash)
      end

      # @param doc_types [Array<Hash>]
      # @return [Hash{String => DocumentType}]
      def parse_doc_types(doc_types)
        doc_types.each_with_object({}) do |data, result|
          doc_type = build_doc_type(data)
          result.store(doc_type.gid, doc_type) if doc_type
        rescue StandardError => e
          Pdfh.logger.error_print e.message, exit_app: false
          Pdfh.logger.backtrace_print e if Pdfh.logger.verbose?
        end
      end

      # @param data [Hash]
      # @return [DocumentType, nil] Document type when valid, otherwise nil.
      def build_doc_type(data)
        doc_type = DocumentType.new(data)
        return doc_type if doc_type.valid?

        log_doc_type_errors(doc_type)
        nil
      end

      # @param doc_type [DocumentType]
      # @return [void]
      def log_doc_type_errors(doc_type)
        doc_type_name = doc_type.name.to_s.colorize(:blue)

        if doc_type.missing_keys?
          missing = doc_type.missing_keys.join(", ").colorize(:red)
          Pdfh.logger.info "Document type '#{doc_type_name}' is missing required keys: #{missing}"
        end

        unless doc_type.path_validator.valid?
          unknown = doc_type.store_path.unknown_list
          Pdfh.logger.info "Document type '#{doc_type_name}', path_validator has invalid keys: #{unknown}"
        end

        return if doc_type.name_validator.valid?

        unknown = doc_type.name_template.unknown_list
        Pdfh.logger.info "Document type '#{doc_type_name}', name_validator has invalid keys: #{unknown}"
      end
    end
  end
end
