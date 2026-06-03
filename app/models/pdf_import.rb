# app/models/pdf_import.rb
 
class PdfImport < ApplicationRecord
  belongs_to :store
 
  validates :pa_counts,   presence: true
  validates :user_counts, presence: true
end
