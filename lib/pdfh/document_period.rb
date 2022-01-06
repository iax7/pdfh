# frozen_string_literal: true

module Pdfh
  # Calculate correct period from the extracted document date and subtype month offset
  class DocumentPeriod
    attr_reader :month, :year

    # @return [self]
    def initialize(month:, month_offset:, year:, day: nil)
      @day = day
      @raw_month = month
      @raw_year = year
      normalized_month = Month.normalize_to_i(month) + (month_offset || 0)
      year_offset = 0
      @month = case normalized_month
               when 0
                 year_offset = -1
                 12
               when 13
                 year_offset = 1
                 1
               else normalized_month
               end
      @year = (year.size == 2 ? "20#{year}" : year).to_i + year_offset
    end

    # @return [String (frozen)]
    def to_s
      "#{year}-#{month.to_s.rjust(2, "0")}"
    end

    # @return [String (frozen)]
    def inspect
      "<#{self.class} year=#{year} month=#{month}>"
    end
  end
end
