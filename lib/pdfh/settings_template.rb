# frozen_string_literal: true

module Pdfh
  # rubocop:disable Layout/HashAlignment
  SETTINGS_TEMPLATE = {
    "lookup_dirs" => ["~/Downloads"].freeze,
    "destination_base_path" => "~/Documents",
    "document_types" => [
      {
        "name"          => "Example Name",
        "re_file"       => ".*file_name\.pdf",
        "re_date"       => "(\d{2})\/(?<m>\w+)\/(?<y>\d{4})",
        "pwd"           => "BASE64_STRING",
        "store_path"    => "{YEAR}/sub folder",
        "name_template" => "{period} {original}",
        "sub_types"     => []
      }.freeze
    ].freeze
  }.freeze
  # rubocop:enable Layout/HashAlignment
end
