# frozen_string_literal: true

FactoryBot.define do
  factory :document, class: :"Pdfh::Document" do
    file { File.expand_path("spec/fixtures/cuenta.pdf") }
    text { "del 06/Enero/2019 al 05/Febrero/2019\nCuenta Tipo: Enlace" }
    date_captures { { "m" => "Enero", "y" => "2019", "d" => "06" } }

    type factory: :document_type

    initialize_with { new(file, type, text, date_captures) }
  end
end
