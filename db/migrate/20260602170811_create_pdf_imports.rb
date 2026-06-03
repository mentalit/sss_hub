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
