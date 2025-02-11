# frozen_string_literal: true

module Pdfh
  # Handles the config yaml data mapping, and associates a file name with a doc type
  class Settings
    attr_reader :lookup_dirs, :base_path

    # @param config_data [Hash]
    # @return [self]
    def initialize(config_data)
      process_lookup_dirs(config_data[:lookup_dirs])
      process_destination_base(config_data[:destination_base_path])

      Pdfh.debug "Configured Look up directories:"
      lookup_dirs.each.with_index(1) { |dir, idx| Pdfh.debug "  #{idx}. #{dir}" }
      Pdfh.debug

      load_doc_types(config_data[:document_types])
    end

    # @return [Array<DocumentType>]
    def document_types
      @document_types.values
    end

    # @return [DocumentType]
    def document_type(id)
      @document_types[id]
    end

    private

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
    def process_destination_base(dir)
      @base_path = File.expand_path(dir)
      raise ArgumentError, "Destination base directory is not configured." if @base_path.nil?
      raise ArgumentError, "Destination base directory #{@base_path} does not exist." unless File.directory?(@base_path)
    end

    # @return [Array<DocumentType>]
    def load_doc_types(doc_types)
      @document_types = doc_types.each_with_object({}) do |data, result|
        doc_type = DocumentType.new(data)
        result.store(doc_type.gid, doc_type)
      rescue ArgumentError => e
        Pdfh.error_print e.message, exit_app: false
        Pdfh.backtrace_print e if Pdfh.verbose?
      end
    end
  end
end
