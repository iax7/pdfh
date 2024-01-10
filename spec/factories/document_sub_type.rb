# frozen_string_literal: true

FactoryBot.define do
  factory :document_sub_type, class: :"Pdfh::DocumentSubType" do
    name         { "Enlace" }
    month_offset { nil }
  end
end
