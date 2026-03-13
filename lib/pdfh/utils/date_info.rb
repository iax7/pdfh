# frozen_string_literal: true

module Pdfh
  # Encapsulates date interpretation from regex captures.
  # Responsible for converting raw captured strings into typed date values
  # and deriving period groupings (quarter, bimester, period string).
  class DateInfo
    # @param date_captures [Hash{String => String}] Captured date components.
    #   Keys: "m" (month — name or number), "y" (year — 2 or 4 digits), "d" (day, optional)
    # @return [self]
    def initialize(date_captures)
      @date_captures = date_captures
    end

    # @return [Hash{String => String}] Raw date captures as provided by the regex match
    def captures
      @date_captures
    end

    # @return [Integer] Normalized month number (1–12)
    def month
      @month ||= Month.normalize_to_i(@date_captures["m"])
    end

    # @return [Integer] Full four-digit year (e.g., 2024)
    def year
      @year ||= begin
        raw = @date_captures["y"]
        (raw.size == 2 ? "20#{raw}" : raw).to_i
      end
    end

    # @return [String, nil] Day of month if captured, nil otherwise
    def day
      @date_captures["d"]
    end

    # Q1: Jan–Mar, Q2: Apr–Jun, Q3: Jul–Sep, Q4: Oct–Dec
    # @return [Integer] Quarter (1–4) based on the month
    def quarter
      @quarter ||= ((month - 1) / 3) + 1
    end

    # B1: Jan–Feb, B2: Mar–Apr, B3: May–Jun, B4: Jul–Aug, B5: Sep–Oct, B6: Nov–Dec
    # @return [Integer] Bimester (1–6) based on the month
    def bimester
      @bimester ||= ((month - 1) / 2) + 1
    end

    # @return [String] Period in format "YYYY-MM"
    def period
      "#{year}-#{month.to_s.rjust(2, "0")}"
    end
  end
end
