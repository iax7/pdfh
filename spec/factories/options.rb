# frozen_string_literal: true

FactoryBot.define do
  factory :options, class: :"Pdfh::Options" do
    verbose { false }
    dry     { false }
    type    { nil }
    files   { [] }
    mode    { :directory }
  end
end
