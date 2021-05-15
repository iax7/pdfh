# frozen_string_literal: true

module Pdfh
  # Handles Month conversions
  class Month
    class << self
      FINDER_3L = proc { |name_search, month| month[0, 3].casecmp?(name_search) }
      FINDER_FL = proc { |name_search, month| month.casecmp?(name_search) }

      # rubocop:disable Layout/SpaceInsideArrayPercentLiteral
      MONTHS_EN = %w[january february march april may  june  july  august september  october november  december].freeze
      MONTHS_ES = %w[enero   febrero  marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre].freeze
      # rubocop:enable Layout/SpaceInsideArrayPercentLiteral

      # @param [String] month
      # @return [Integer]
      def normalize_to_i(month)
        # When param is a number
        month_num = month.to_i
        raise ArgumentError, "Month #{month.inspect} is not a valid month number" if month_num > 12

        return month_num if month_num.between?(1, 12)

        # When param is a 3 char month: 'mar', 'nov'
        return find_month(month, FINDER_3L) if month.size == 3

        # When param has a direct match
        find_month(month, FINDER_FL)
      end

      private

      # @return [Integer]
      def find_month(name, finder)
        find_by_name = finder.curry[name]
        match = MONTHS_ES.find(&find_by_name)
        return month_number(MONTHS_ES, match) if match

        match = MONTHS_EN.find(&find_by_name)
        return month_number(MONTHS_EN, match) if match

        raise ArgumentError, "Month #{name.inspect} is not valid"
      end

      # @return [Integer]
      def month_number(month_array, name)
        month_array.rindex(name) + 1
      end
    end
  end
end
