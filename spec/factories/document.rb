# frozen_string_literal: true

FactoryBot.define do
  factory :document, class: :"Pdfh::Document" do
    file { File.expand_path("spec/fixtures/cuenta.pdf") }
    text { "del 06/Enero/2019 al 05/Febrero/2019\nCuenta Tipo: Enlace" }

    type factory: :document_type

    initialize_with { new(file, type, text) }
  end
end
