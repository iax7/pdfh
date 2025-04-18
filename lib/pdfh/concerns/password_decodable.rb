# frozen_string_literal: true

module Pdfh
  module Concerns
    # Module that provides password handling capabilities for classes that contain
    # password attributes. It handles Base64-encoded passwords by automatically
    # detecting and decoding them when accessed through the password method.
    module PasswordDecodable
      # Returns the decoded password if it's Base64 encoded, otherwise returns it as is
      # @return [String]
      def password
        return Base64.decode64(pwd) if base64?

        pwd
      end

      private

      # @return [boolean]
      def base64?
        pwd.is_a?(String) && Base64.strict_encode64(Base64.decode64(pwd)) == pwd
      end
    end
  end
end
