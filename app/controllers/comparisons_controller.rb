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
    @selected_pdf = if params[:pdf_import_id]
                      @store.pdf_imports.find(params[:pdf_import_id])
                    elsif pdf.count == 1
                      pdf.first
                    end
 
    tracker_counts = @store.trackers
                           .where(date: @date)
                           .where.not(counter: [nil, ""])
                           .group(:counter)
                           .count
 
    tracker_total = tracker_counts.values.sum
    pdf_total     = @selected_pdf ? @selected_pdf.user_counts.values.sum : 0
    pdf_counts    = @selected_pdf ? @selected_pdf.user_counts : {}
 
    @chart_data    = { @date.strftime("%b %d") => percentage(tracker_total, pdf_total) }
    @user_charts   = build_user_pie_charts(pdf_counts, tracker_counts)
    @loss_total    = calculate_loss(@date, @date)
    @comparison    = build_comparison_rows(pdf_counts, tracker_counts) if @selected_pdf
  end
 
  def week
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    end_date   = start_date.end_of_week
 
    tracker_counts, pdf_counts = aggregated_counts(start_date, end_date)
 
    @chart_data   = build_chart_data_by_day(start_date, end_date)
    @user_charts  = build_user_pie_charts(pdf_counts, tracker_counts)
    @loss_total   = calculate_loss(start_date, end_date)
    @period_label = "#{start_date.strftime('%b %d')} – #{end_date.strftime('%b %d, %Y')}"
  end
 
  def month
    date       = params[:month] ? Date.parse("#{params[:month]}-01") : Date.today
    start_date = date.beginning_of_month
    end_date   = date.end_of_month
 
    tracker_counts, pdf_counts = aggregated_counts(start_date, end_date)
 
    @chart_data   = build_chart_data_by_day(start_date, end_date)
    @user_charts  = build_user_pie_charts(pdf_counts, tracker_counts)
    @loss_total   = calculate_loss(start_date, end_date)
    @period_label = date.strftime("%B %Y")
  end
 
  def year
    # Fiscal year: September 1 – August 31
    # Determine the fiscal year start based on the selected or current year
    year = params[:year] ? params[:year].to_i : Date.today.year
    
    # If we're before September, the fiscal year started last year
    fiscal_year_start = if params[:year]
                          Date.new(year, 9, 1)
                        elsif Date.today.month < 9
                          Date.new(Date.today.year - 1, 9, 1)
                        else
                          Date.new(Date.today.year, 9, 1)
                        end

    start_date = fiscal_year_start
    end_date   = fiscal_year_start + 1.year - 1.day  # August 31

    tracker_counts, pdf_counts = aggregated_counts(start_date, end_date)

    @chart_data   = build_chart_data_by_month(start_date, end_date)
    @user_charts  = build_user_pie_charts(pdf_counts, tracker_counts)
    @loss_total   = calculate_loss(start_date, end_date)
    @period_label = "FY #{start_date.strftime('%b %Y')} – #{end_date.strftime('%b %Y')}"
  end
 
  def life
    first_date = @store.trackers.minimum(:date) || Date.today
    last_date  = @store.trackers.maximum(:date) || Date.today
 
    tracker_counts, pdf_counts = aggregated_counts(first_date, last_date)
 
    @chart_data   = build_chart_data_by_month(first_date, last_date)
    @user_charts  = build_user_pie_charts(pdf_counts, tracker_counts)
    @loss_total   = calculate_loss(first_date, last_date)
    @period_label = "All Time"
  end


  # Add these to ComparisonsController, alongside the existing actions

  
  
 
  private
 
  # def set_store
  #   @store = Store.find(params[:store_id])
  # end

  def set_store
    @store = Store.find(params[:store_id] || 1)
  end

  # Add these to the private section of ComparisonsController


  end
 
  def shared_dates
    pdf_dates     = @store.pdf_imports.pluck(:report_date).uniq.compact
    tracker_dates = @store.trackers.pluck(:date).uniq.compact
    (pdf_dates & tracker_dates).sort.reverse
  end
 
 
  def calculate_loss(start_date, end_date)
    @store.trackers
          .where(date: start_date..end_date)
          .where.not(counted: nil)
          .where.not(sss_inv_count: nil)
          .where.not(price: nil)
          .sum("(counted - sss_inv_count) * price")
          .round(2)
  end
 
  def aggregated_counts(start_date, end_date)
  tracker_counts = @store.trackers
                         .where(date: start_date..end_date)
                         .where.not(counter: [nil, ""])
                         .group(:counter)
                         .count
                         .each_with_object(Hash.new(0)) do |(counter, count), hash|
                           hash[counter.strip] += count
                         end

  tracker_counts.keys.each do |user_id|
    Counter.find_or_create_by(store_id: @store.id, user_id: user_id)
  end

  pdf_counts = @store.pdf_imports
                     .where(report_date: start_date..end_date)
                     .each_with_object(Hash.new(0)) do |import, hash|
                       import.user_counts.each do |user, count|
                         hash[user] += count
                       end
                     end

  pdf_counts.keys.each do |user_id|
    Counter.find_or_create_by(store_id: @store.id, user_id: user_id)
  end

  [tracker_counts, pdf_counts]
end
# This auto-creates counters for both tracker users and PDF users, so every name in the charts gets a link.
 
  def build_user_pie_charts(pdf_counts, tracker_counts)
    all_users = (pdf_counts.keys + tracker_counts.keys).uniq.sort
    all_users.each_with_object({}) do |user_id, hash|
      pdf_count     = pdf_counts[user_id].to_i
      tracker_count = tracker_counts[user_id].to_i
      accurate      = [pdf_count - tracker_count, 0].max
      hash[user_id] = { "Accurate" => accurate, "Inaccurate" => tracker_count }
    end
  end
 
  def build_chart_data_by_day(start_date, end_date)
    tracker_by_date = @store.trackers
                            .where(date: start_date..end_date)
                            .group(:date)
                            .count
 
    pdf_by_date = @store.pdf_imports
                        .where(report_date: start_date..end_date)
                        .each_with_object(Hash.new(0)) do |import, hash|
                          hash[import.report_date] += import.user_counts.values.sum
                        end
 
    (start_date..end_date).each_with_object({}) do |date, hash|
      t = tracker_by_date[date] || 0
      p = pdf_by_date[date] || 0
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
 
  def build_comparison_rows(pdf_counts, tracker_counts)
    all_users = (pdf_counts.keys + tracker_counts.keys).uniq.sort
    all_users.map do |user_id|
      {
        user_id:       user_id,
        pdf_count:     pdf_counts[user_id] || 0,
        tracker_count: tracker_counts[user_id] || 0
      }
    end
  
end