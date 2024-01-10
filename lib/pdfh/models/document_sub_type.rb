# frozen_string_literal: true

module Pdfh
  # Provides a way to divide document type by subtypes, for different name, and month adjustments
  DocumentSubType = Struct.new(:name, :month_offset, keyword_init: true)
end
