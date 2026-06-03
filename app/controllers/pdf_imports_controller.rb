# app/controllers/pdf_imports_controller.rb

class PdfImportsController < ApplicationController
  before_action :set_store
  before_action :set_pdf_import, only: [:show]

  def index
    @pdf_imports = @store.pdf_imports.order(report_date: :desc, created_at: :desc)
  end

  def show
  end

  def new
  end

  def create
    files = Array(params[:pdf_files]).select { |f| f.respond_to?(:read) }

    if files.empty?
      flash.now[:alert] = "Please select at least one PDF file."
      return render :new, status: :unprocessable_entity
    end

    imported = []
    skipped  = []
    errors   = []

    files.each do |file|
      result = PdfImportService.new(file).call

      if result[:error].present?
        errors << "#{file.original_filename}: #{result[:error]}"
        next
      end

      if result[:date] && @store.pdf_imports.exists?(report_date: result[:date])
        skipped << "#{file.original_filename} (#{result[:date]} already imported)"
        next
      end

      pdf_import = @store.pdf_imports.build(
        report_date: result[:date],
        pa_counts:   result[:pa_counts],
        user_counts: result[:user_counts]
      )

      if pdf_import.save
        imported << file.original_filename
      else
        errors << "#{file.original_filename}: #{pdf_import.errors.full_messages.to_sentence}"
      end
    end

    messages = []
    messages << "Imported: #{imported.join(', ')}"             if imported.any?
    messages << "Skipped (duplicates): #{skipped.join(', ')}"  if skipped.any?
    messages << "Errors: #{errors.join(', ')}"                 if errors.any?

    redirect_to store_pdf_imports_path(@store), notice: messages.join(" | ")
  end

  private

  def set_store
    @store = Store.find(params[:store_id])
  end

  def set_pdf_import
    @pdf_import = PdfImport.find(params[:id])
    @store      ||= @pdf_import.store
  end
end