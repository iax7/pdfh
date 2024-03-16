# frozen_string_literal: true

module Pdfh
  # Validates the rename template, and generate new name
  class RenameValidator
    RENAME_TYPES = {
      "original" => "No name change",
      "period"   => "Year-Month",
      "year"     => "Year",
      "month"    => "Month",
      "type"     => "Document Type name",
      "subtype"  => "Document Subtype name",
      "extra"    => "Extra data extracted from date_re"
    }.freeze

    attr_reader :name_template, :all, :unknown, :valid

    # @param name_template [String]
    # @return [self]
    def initialize(name_template)
      @name_template = name_template
      @all = name_template.scan(/{(\w+)}/).flatten
      @unknown = all - types
      @valid = all - unknown
    end

    # @return [Array<String>]
    def types
      RENAME_TYPES.keys
    end

    # @return [Boolean]
    def valid?
      unknown.empty?
    end

    # @param values [Hash{Symbol->String}]
    # @return [String (frozen)]
    def name(values)
      new_name = name_template.gsub("{", "%{") % values
      "#{new_name}.pdf"
    end
  end
end
