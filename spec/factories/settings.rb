# frozen_string_literal: true

FactoryBot.define do
  factory :settings, class: :"Pdfh::Settings" do
    transient do
      doc_type { association(:document_type) }
    end

    lookup_dirs { [Dir.tmpdir] }
    base_path   { Dir.tmpdir }
    document_types { { doc_type.gid => doc_type } }

    initialize_with do
      new(**attributes)
    end
  end
end
