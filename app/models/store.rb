class Store < ApplicationRecord
    has_many :trackers #excel
    has_many :pdf_imports, dependent: :destroy #8144
    has_many :counters
end
