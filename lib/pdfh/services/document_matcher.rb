# frozen_string_literal: true

module Pdfh
  module Services
    # Matches a PDF file against settings and builds a Document if valid
    class DocumentMatcher
      # @param document_types [Array<DocumentType>]
      # @return [DocumentMatcher]
      def initialize(document_types)
        @document_types = document_types
      end

      # @param file [String] Path to the PDF file
      # @param text [String] Extracted text from the PDF
      # @return [Array<Document>]
      def match(file, text)
        @document_types.each_with_object([]) do |type, matches|
          # Try to match the document type by ID (filename or content)
          next unless type.re_id.match?(text)

          Pdfh.logger.debug "Matched document type: #{type.name}"

          # Try to match the date in the text
          date_match = type.re_date.match(text)
          unless date_match
            Pdfh.logger.debug "No date match found for #{type.name}"
            next
          end

          # Extract date captures (handles both named and positional captures)
          date_captures = extract_date_captures(date_match)

          matches << Document.new(file, type, text, date_captures)
        end
      end

      private

      # Extracts date captures from MatchData, supporting both named and positional captures
      # @param match_data [MatchData]
      # @return [Hash{String => String}] Hash with keys 'm' (month), 'y' (year), 'd' (day)
      def extract_date_captures(match_data)
        captures = {}

        # Try named captures first (preferred method)
        if match_data.names.any?
          captures = match_data.named_captures
          Pdfh.logger.debug "Using #{"named".colorize(:green)} captures: #{captures.inspect}"
        else
          # Fall back to positional captures
          # Assume order: [month, year, day?]
          captured_values = match_data.captures
          captures["m"] = captured_values[0] if captured_values[0]
          captures["y"] = captured_values[1] if captured_values[1]
          captures["d"] = captured_values[2] if captured_values[2]
          Pdfh.logger.debug "Using #{"positional".colorize(:red)} captures: #{captures.inspect}"
        end

        captures
      end
    end
  end
end
