# frozen_string_literal: true

##
# Extends String class when required
module Extensions
  ##
  # Adds new functionality to string Class
  refine String do
    def titleize
      split.map(&:capitalize).join(' ')
    end
  end
end
