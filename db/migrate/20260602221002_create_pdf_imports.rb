# db/migrate/YYYYMMDDHHMMSS_create_pdf_imports.rb
# Rename with the correct timestamp, e.g.:
#   bin/rails generate migration CreatePdfImports
# then replace the generated file's content with this, OR just create the file directly.

class CreatePdfImports < ActiveRecord::Migration[8.1]
  def change
    create_table :pdf_imports do |t|
      t.references :store, null: false, foreign_key: true
      t.date    :report_date
      t.jsonb   :pa_counts,   null: false, default: {}
      t.jsonb   :user_counts, null: false, default: {}

      t.timestamps
    end
  end
end