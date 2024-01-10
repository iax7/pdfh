# frozen_string_literal: true

FactoryBot.define do
  factory :settings, class: :"Pdfh::Settings" do
    lookup_dirs           { ["~/Downloads"] }
    destination_base_path { "/tmp" }
    document_types        { [] }

    initialize_with do
      new(**attributes)
    end
  end
end
