# frozen_string_literal: true

FactoryBot.define do
  factory :options, class: :"Pdfh::Options" do
    verbose { false }
    dry     { false }

    trait :file_mode do
      type  { "example-name" }
      files { [File.expand_path("spec/fixtures/cuenta.pdf")] }
    end
  end
end
