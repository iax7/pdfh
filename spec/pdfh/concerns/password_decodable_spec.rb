# frozen_string_literal: true

require "base64"

RSpec.describe Pdfh::Concerns::PasswordDecodable do
  let(:test_class) do
    Class.new do
      include Pdfh::Concerns::PasswordDecodable
      attr_accessor :pwd

      def initialize(pwd)
        @pwd = pwd
      end
    end
  end

  describe "#password" do
    context "when pwd is a valid Base64 encoded string" do
      let(:original_password) { "secretpassword" }
      let(:encoded_password) { Base64.strict_encode64(original_password) }

      subject { test_class.new(encoded_password) }

      it "decodes the Base64 encoded password" do
        expect(subject.password).to eq(original_password)
      end
    end

    context "when pwd is not a Base64 encoded string" do
      subject { test_class.new(plain_password) }

      let(:plain_password) { "plain123!" }

      it "returns the password as is" do
        expect(subject.password).to eq(plain_password)
      end
    end

    context "when pwd is nil" do
      subject { test_class.new(nil) }

      it "handles nil gracefully" do
        expect { subject.password }.not_to raise_error
      end
    end
  end
end
