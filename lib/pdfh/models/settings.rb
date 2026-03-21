# frozen_string_literal: true

module Pdfh
  # Handles the config yaml data mapping, and associates a file name with a doc type.
  # This is a pure data object — validation is handled by Services::SettingsValidator.
  class Settings
    # @!attribute [r] lookup_dirs
    #   @return [Array<String>] List of validated, expanded directories to look up for processing.
    # @!attribute [r] base_path
    #   @return [String] The validated, expanded base directory path for storing processed files.
    attr_reader :lookup_dirs, :base_path

    # @param lookup_dirs [Array<String>] Already validated and expanded directories
    # @param base_path [String] Already validated and expanded base path
    # @param document_types [Hash{String => DocumentType}] Already validated document types keyed by gid
    # @return [Settings]
    def initialize(lookup_dirs:, base_path:, document_types:)
      @lookup_dirs = lookup_dirs
      @base_path = base_path
      @document_types = document_types
    end

    # @return [Array<DocumentType>]
    def document_types = @document_types.values

    # @example
    #   # document_types.map(&:name) ['12345', '12', '123']
    #   settings.document_types_name_max_size #=> 5
    # @return [Integer]
    def document_types_name_max_size
      return 0 if document_types.empty?

      document_types.map { _1.name.length }.max
    end

    # @return [DocumentType]
    def document_type(id)
      @document_types[id]
    end
  end
end
