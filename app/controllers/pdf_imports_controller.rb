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
    unless params[:pdf_file].present?
      flash.now[:alert] = "Please select a PDF file."
      return render :new, status: :unprocessable_entity
    end

    result = PdfImportService.new(params[:pdf_file]).call

    if result[:error].present?
      flash.now[:alert] = "Could not parse PDF: #{result[:error]}"
      return render :new, status: :unprocessable_entity
    end

    @pdf_import = @store.pdf_imports.build(
      report_date: result[:date],
      pa_counts:   result[:pa_counts],
      user_counts: result[:user_counts]
    )

    if @pdf_import.save
      redirect_to pdf_import_path(@pdf_import), notice: "PDF imported successfully."
    else
      flash.now[:alert] = "Could not save import: #{@pdf_import.errors.full_messages.to_sentence}"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_store
    if params[:store_id]
        @store = Store.find(params[:store_id])
      else
        @store = PdfImport.find(params[:id]).store
      end
  end

  def set_pdf_import
    @pdf_import = @store.pdf_imports.find(params[:id])
  end
end