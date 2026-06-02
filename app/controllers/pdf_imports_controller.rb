# app/controllers/pdf_imports_controller.rb

require "open3"
require "json"
require "tempfile"

class PdfImportsController < ApplicationController
  before_action :set_store

  def new
  end

 def debug
  require "pdf-reader"
  reader = PDF::Reader.new("/tmp/test_debug.pdf")
  lines = []
  reader.pages.each_with_index do |page, i|
    page.text.each_line do |line|
      stripped = line.chomp
      lines << "P#{i+1}|#{stripped}" if stripped.match?(/ALVEN|ROKRA|456306|618846|490471|535361|541822|531891|539066|556329|556244|597174|600415|426691|575540/)
    end
  end
  render plain: lines.join("\n")
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

    @date        = result[:date]
    @pa_counts   = result[:pa_counts]
    @user_counts = result[:user_counts]

    render :results
  end

  private

  def set_store
    @store = Store.find(params[:store_id])
  end
end