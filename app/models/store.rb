class Store < ApplicationRecord
    has_many :trackers
    has_many :pdf_imports, dependent: :destroy
end
