# frozen_string_literal: true

# Adds :titleize to string Class
class String
  # @return [String]
  def titleize
    split.map(&:capitalize).join(" ")
  end
end
