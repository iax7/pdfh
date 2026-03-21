# frozen_string_literal: true

module Pdfh
  # Validates the rename template, and generate new name
  class RenameValidator
    RENAME_TYPES = {
      "original" => "No name change",
      "period"   => "Year-Month",
      "year"     => "Year",
      "month"    => "Month",
      "quarter"  => "Quarter (Q1-Q4)",
      "bimester" => "Bimester (B1-B6)",
      "name"     => "Document Type name",
      "day"      => "Day of month"
    }.freeze

    attr_reader :template, :all, :unknown, :valid

    # @param template [String]
    # @return [self]
    def initialize(template)
      @template = template
      @all = template.scan(/{([^}]+)}/).flatten.map(&:downcase)
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

    # @return [String]
    def unknown_list
      unknown.join(", ")
    end

    # @param values [Hash{Symbol->String}]
    # @return [String (frozen)]
    def gsub(values)
      template
        .gsub(/\{([^}]+)}/, &:downcase) # convert all text between {} to lowercase
        .gsub("{", "%{") % values
    end
  end
end
