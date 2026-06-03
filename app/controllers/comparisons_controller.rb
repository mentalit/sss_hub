# app/controllers/comparisons_controller.rb

class ComparisonsController < ApplicationController
  before_action :set_store

  def index
    @shared_dates = shared_dates
  end

  def day
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    pdf   = @store.pdf_imports.where(report_date: @date).order(created_at: :desc)
    
    @pdf_imports_for_date = pdf
    @selected_pdf = params[:pdf_import_id] ? @store.pdf_imports.find(params[:pdf_import_id]) : (pdf.count == 1 ? pdf.first : nil)

    tracker_total = @store.trackers.where(date: @date).count
    pdf_total     = @selected_pdf ? @selected_pdf.user_counts.values.sum : 0

    @chart_data = { @date.strftime("%b %d") => percentage(tracker_total, pdf_total) }
    @comparison = build_comparison(@selected_pdf, @date) if @selected_pdf
  end

  def week
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    end_date   = start_date.end_of_week

    @chart_data = build_chart_data_by_day(start_date, end_date)
    @period_label = "#{start_date.strftime('%b %d')} – #{end_date.strftime('%b %d, %Y')}"
  end

  def month
    date       = params[:month] ? Date.parse(params[:month]) : Date.today
    start_date = date.beginning_of_month
    end_date   = date.end_of_month

    @chart_data = build_chart_data_by_day(start_date, end_date)
    @period_label = date.strftime("%B %Y")
  end

  def year
    date       = params[:year] ? Date.parse("#{params[:year]}-01-01") : Date.today
    start_date = date.beginning_of_year
    end_date   = date.end_of_year

    @chart_data = build_chart_data_by_month(start_date, end_date)
    @period_label = date.strftime("%Y")
  end

  def life
    first_date = @store.trackers.minimum(:date) || Date.today
    last_date  = @store.trackers.maximum(:date) || Date.today

    @chart_data = build_chart_data_by_month(first_date, last_date)
    @period_label = "All Time"
  end

  private

  def set_store
    @store = Store.find(params[:store_id])
  end

  def shared_dates
    pdf_dates     = @store.pdf_imports.pluck(:report_date).uniq.compact
    tracker_dates = @store.trackers.pluck(:date).uniq.compact
    (pdf_dates & tracker_dates).sort.reverse
  end

  def percentage(tracker_count, pdf_total)
    return 0 if pdf_total.zero?
    ((tracker_count.to_f / pdf_total) * 100).round(2)
  end

  def build_chart_data_by_day(start_date, end_date)
    # Tracker counts grouped by date
    tracker_counts = @store.trackers
                           .where(date: start_date..end_date)
                           .group(:date)
                           .count

    # PDF totals grouped by date (sum user_counts values for each import)
    pdf_totals = @store.pdf_imports
                       .where(report_date: start_date..end_date)
                       .each_with_object(Hash.new(0)) do |import, hash|
                         hash[import.report_date] += import.user_counts.values.sum
                       end

    (start_date..end_date).each_with_object({}) do |date, hash|
      t = tracker_counts[date] || 0
      p = pdf_totals[date] || 0
      hash[date.strftime("%b %d")] = percentage(t, p)
    end
  end

  def build_chart_data_by_month(start_date, end_date)
    tracker_counts = @store.trackers
                           .where(date: start_date..end_date)
                           .group_by_month(:date, format: "%b %Y")
                           .count

    pdf_totals = @store.pdf_imports
                       .where(report_date: start_date..end_date)
                       .each_with_object(Hash.new(0)) do |import, hash|
                         key = import.report_date.strftime("%b %Y")
                         hash[key] += import.user_counts.values.sum
                       end

    all_keys = (tracker_counts.keys + pdf_totals.keys).uniq.sort_by { |k| Date.parse("01 #{k}") }
    all_keys.each_with_object({}) do |key, hash|
      t = tracker_counts[key] || 0
      p = pdf_totals[key] || 0
      hash[key] = percentage(t, p)
    end
  end

  def build_comparison(pdf_import, date)
    tracker_counts = @store.trackers
                           .where(date: date)
                           .where.not(counter: [nil, ""])
                           .group(:counter)
                           .count

    all_users = (pdf_import.user_counts.keys + tracker_counts.keys).uniq.sort
    all_users.map do |user_id|
      {
        user_id:       user_id,
        pdf_count:     pdf_import.user_counts[user_id] || 0,
        tracker_count: tracker_counts[user_id] || 0
      }
    end
  end
end