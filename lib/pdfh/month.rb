# frozen_string_literal: true

module Pdfh
  ##
  # Handles Month convertions
  class Month
    MONTHS = {
      enero: 1,
      febrero: 2,
      marzo: 3,
      abril: 4,
      mayo: 5,
      junio: 6,
      julio: 7,
      agosto: 8,
      septiembre: 9,
      octubre: 10,
      noviembre: 11,
      diciembre: 12
    }.freeze

    ##
    # @param [String] month
    # @return [Integer]
    def self.normalize(month)
      # When param is a number
      month_num = month.to_i
      return month_num if month_num.between?(1, 12) # (1..12).include?(month_num)

      # When param is a 3 char month: 'mar', 'nov'
      if month.size == 3
        MONTHS.each_key do |mon|
          return MONTHS[mon] if mon.to_s[0, 3] == month
        end
      end

      # When param has a direct match
      MONTHS[month.to_sym]
    end
  end
end
