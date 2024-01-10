# frozen_string_literal: true

FactoryBot.define do
  factory :document_type, class: :"Pdfh::DocumentType" do
    name          { "Cuenta" }
    re_file       { /cuenta\.pdf/ }
    re_date       { %r{\d{2}/(?<m>\w+)/(?<y>\d{4})} }
    pwd           { nil }
    store_path    { "{YEAR}/Edo Cuenta" }
    name_template { "{period} {type} {subtype}" }

    sub_types     { create_list(:document_sub_type, 1) }
  end
end
