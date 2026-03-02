# frozen_string_literal: true

module Pdfh
  module Services
    # Scans lookup dirs and returns matched documents
    class DirectoryScanner
      # @param directories [Array<String>]
      # @return [DirectoryScanner]
      def initialize(directories)
        @directories = directories
      end

      # @return [Array<String>]
      def scan
        @directories.flat_map { |dir| scan_dir(dir) }
      end

      private

      # @param dir [String]
      # @return [Array<String>]
      def scan_dir(dir)
        Dir.glob(File.join(dir, "*.pdf"))
      end
    end
  end
end
