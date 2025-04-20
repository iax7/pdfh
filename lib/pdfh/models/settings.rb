# frozen_string_literal: true

module Pdfh
  # Handles the config yaml data mapping, and associates a file name with a doc type
  class Settings
    # @!attribute [r] lookup_dirs
    #   @return [Array<String>] List of directories to look up for processing.
    # @!attribute [r] base_path
    #   @return [String] The base directory path for storing processed files.
    # @!attribute [r] zip_types
    #   @return [Array<ZipType>, nil] List of zip types to process, or nil if none.
    attr_reader :lookup_dirs, :base_path, :zip_types

    # @param config_data [Hash]
    # @return [self]
    def initialize(config_data)
      process_lookup_dirs(config_data[:lookup_dirs])
      process_destination_base(config_data[:destination_base_path])

      Pdfh.debug "Configured Look up directories:"
      lookup_dirs.each.with_index(1) { |dir, idx| Pdfh.debug "  #{idx}. #{dir}" }
      Pdfh.debug

      build_doc_types(config_data[:document_types])
      build_zip_types(config_data[:zip_types]) if config_data.key?(:zip_types)
    end

    # @return [Array<DocumentType>]
    def document_types
      @document_types.values
    end

    # @return [DocumentType]
    def document_type(id)
      @document_types[id]
    end

    # @return [Boolean]
    def zip_types?
      !!zip_types&.any?
    end

    private

    # @param lookup_dirs_list [Array[String]]
    # @return [void]
    def process_lookup_dirs(lookup_dirs_list)
      @lookup_dirs = lookup_dirs_list.filter_map do |dir|
        expanded = File.expand_path(dir)
        unless File.directory?(expanded)
          Pdfh.debug "  ** Error, Directory #{dir} does not exists."
          next
        end
        expanded
      end
      raise ArgumentError, "No valid Look up directories configured." if lookup_dirs.empty?
    end

    # @return [void]
    # @param dir [String]
    def process_destination_base(dir)
      @base_path = File.expand_path(dir)
      raise ArgumentError, "Destination base directory is not configured." if @base_path.nil?
      raise ArgumentError, "Destination base directory #{@base_path} does not exist." unless File.directory?(@base_path)
    end

    # @param doc_types [Array<Hash>]
    # @return [void]
    def build_doc_types(doc_types)
      @document_types = doc_types.each_with_object({}) do |data, result|
        doc_type = DocumentType.new(data)
        result.store(doc_type.gid, doc_type)
      rescue ArgumentError => e
        Pdfh.error_print e.message, exit_app: false
        Pdfh.backtrace_print e if Pdfh.verbose?
      end
    end

    # @param zip_types [Array<Hash>]
    # @return [void]
    def build_zip_types(zip_types)
      exit(1) if Pdfh::Utils::DependencyValidator.missing?(:unzip)

      @zip_types = zip_types.compact.map { ZipType.new(_1) }
    end
  end
end
