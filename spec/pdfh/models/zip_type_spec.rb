# frozen_string_literal: true

RSpec.describe Pdfh::ZipType do
  let(:valid_attributes) do
    {
      name: "Test Zip",
      re_file: "test.*\\.zip",
      pwd: "password123"
    }
  end

  describe "#initialize" do
    subject { described_class.new(valid_attributes) }

    it "creates a new zip type" do
      expect(subject).to be_a(described_class)
    end

    it "sets attributes from hash" do
      expect(subject.name).to eq("Test Zip")
      expect(subject.pwd).to eq("password123")
    end

    it "converts regex string to actual regex object" do
      expect(subject.re_file).to be_a(Regexp)
      expect("test_file.zip").to match(subject.re_file)
      expect("other.pdf").not_to match(subject.re_file)
    end
  end

  describe "password handling" do
    context "with Base64 encoded password" do
      let(:original_password) { "secretpassword" }
      let(:encoded_password) { Base64.strict_encode64(original_password) }
      let(:zip_type) { described_class.new(valid_attributes.merge(pwd: encoded_password)) }

      it "decodes the Base64 encoded password" do
        expect(zip_type).to respond_to(:password)
        expect(zip_type.password).to eq(original_password)
      end
    end

    context "with plain text password" do
      let(:plain_password) { "plain123!" }
      let(:zip_type) { described_class.new(valid_attributes.merge(pwd: plain_password)) }

      it "returns the password as is" do
        expect(zip_type.password).to eq(plain_password)
      end
    end
  end
end
