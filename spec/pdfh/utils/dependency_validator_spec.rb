# frozen_string_literal: true

RSpec.describe Pdfh::Utils::DependencyValidator do
  let(:all_existing_apps) { %w[ruby git] }
  let(:one_missing_apps) { %w[ruby nonexistent-app] }

  # @param success [Boolean]
  # @return [Double]
  def result(success)
    instance_double(Process::Status, success?: success)
  end

  describe ".installed?" do
    context "when all applications are installed" do
      before do
        allow(Open3).to receive(:capture3).and_return(["", "", result(true)])
      end

      it "returns true" do
        expect(described_class.installed?(all_existing_apps)).to be true
      end

      it "doesn't output any messages" do
        expect { described_class.installed?(*all_existing_apps) }.not_to output.to_stdout
      end
    end

    context "when some applications are missing" do
      before do
        # Mock successful execution for git but failed for nonexistent-app
        allow(Open3).to receive(:capture3).with("which ruby").and_return(["", "", result(true)])
        allow(Open3).to receive(:capture3).with("which nonexistent-app").and_return(["", "", result(false)])
      end

      it "returns false" do
        allow(described_class).to receive(:puts)

        expect(described_class.installed?(*one_missing_apps)).to be false
      end

      it "outputs an error message with the missing apps" do
        expect { described_class.installed?(*one_missing_apps) }.to output(/nonexistent-app/).to_stdout
      end
    end

    context "when passing nil values in the array" do
      before do
        allow(Open3).to receive(:capture3).with("which ").and_return(["", "", result(false)])
      end

      it "handles nil values gracefully" do
        allow(described_class).to receive(:puts)

        expect { described_class.installed?(nil) }.not_to raise_error
      end
    end
  end

  describe ".missing?" do
    context "when all applications are installed" do
      before do
        allow(described_class).to receive(:installed?).and_return(true)
      end

      it "returns false" do
        expect(described_class.missing?(*all_existing_apps)).to be false
      end
    end
  end
end
