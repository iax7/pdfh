# frozen_string_literal: true

require "shellwords"
require "english"

module Pdfh
  module Services
    # Extracts text from a PDF using pdftotext command
    class PdfTextExtractor
      # @param pdf_path [String]
      # @return [String]
      # @raise [ArgumentError] if file doesn't exist or is not a PDF
      # @raise [RuntimeError] if extraction fails
      def self.call(pdf_path)
        validate_file!(pdf_path)

        # Use Shellwords to properly escape the path for shell execution
        safe_path = Shellwords.escape(pdf_path)
        cmd = "pdftotext -enc UTF-8 -layout #{safe_path} - 2>/dev/null"

        text = `#{cmd}`
        exit_status = $CHILD_STATUS

        # Check if command executed successfully
        if exit_status.nil? || !exit_status.success?
          Pdfh.logger.debug "Failed to extract text from: #{pdf_path}"
          return ""
        end

        text
      end

      # @param pdf_path [String]
      # @return [void]
      # @raise [ArgumentError] if validation fails
      def self.validate_file!(pdf_path)
        raise ArgumentError, "PDF path cannot be nil" if pdf_path.nil?
        raise ArgumentError, "PDF path cannot be empty" if pdf_path.empty?
        raise ArgumentError, "File does not exist: #{pdf_path}" unless File.exist?(pdf_path)
        raise ArgumentError, "Not a file: #{pdf_path}" unless File.file?(pdf_path)
        raise ArgumentError, "Not a PDF file: #{pdf_path}" unless File.extname(pdf_path).casecmp?(".pdf")
      end
    end
  end
end
