# frozen_string_literal: true

FactoryBot.define do
  factory :document_type, class: :"Pdfh::DocumentType" do
    name          { "Cuenta" }
    re_id         { /cuenta\.pdf/ }
    re_date       { %r{\d{2}/(?<m>\w+)/(?<y>\d{4})} }
    store_path    { "{year}/Edo Cuenta" }
    name_template { "{period} {name}" }
  end
end
