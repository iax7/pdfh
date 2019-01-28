# frozen_string_literal: true

module Pdfh::String
    refine String do
        def titleize
            split.map(&:capitalize).join(' ')
        end
    end
end
