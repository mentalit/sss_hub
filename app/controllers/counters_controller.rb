class CountersController < ApplicationController
  before_action :set_counter,
              only: %i[
                show edit update destroy
                day week month year life show
              ]

  before_action :get_store, only: %i[ new create index  ]


  # GET /counters or /counters.json
  def index
    @counters = @store.counters
  end

  # GET /counters/1 or /counters/1.json
  def show
  @date = params[:date] ? Date.parse(params[:date]) : Date.today
  user_id = @counter.user_id

  pdf_count     = aggregated_pdf_counts_for_user(@date, @date, user_id)
  tracker_count = aggregated_tracker_counts_for_user(@date, @date, user_id)

  @chart_data  = { @date.strftime("%b %d") => percentage(tracker_count, pdf_count) }
  @user_charts = build_single_user_pie(user_id, @date, @date)
  @loss_total  = calculate_loss_for_user(@date, @date, user_id)
  @period_label = "#{user_id} - #{@date.strftime('%B %d, %Y')}"
end

  # GET /counters/new
  def new
    @counter = @store.counters.build
  end

  # GET /counters/1/edit
  def edit
  end

  # POST /counters or /counters.json
  def create
    @counter = @store.counters.build(counter_params)

    respond_to do |format|
      if @counter.save
        format.html { redirect_to @counter, notice: "Counter was successfully created." }
        format.json { render :show, status: :created, location: @counter }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @counter.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /counters/1 or /counters/1.json
  def update
    respond_to do |format|
      if @counter.update(counter_params)
        format.html { redirect_to @counter, notice: "Counter was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @counter }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @counter.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /counters/1 or /counters/1.json
  def destroy
    @counter.destroy!

    respond_to do |format|
      format.html { redirect_to counters_path, notice: "Counter was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end


  # Counter functions##################################

  def day
  @date = params[:date] ? Date.parse(params[:date]) : Date.today

  pdf = aggregated_pdf_counts_for_user(
    @date,
    @date,
    @counter.user_id
  )

  tracker = aggregated_tracker_counts_for_user(
    @date,
    @date,
    @counter.user_id
  )

  @chart_data = {
    @date.strftime("%b %d") => percentage(tracker, pdf)
  }

  @loss_total = calculate_loss_for_user(
    @date,
    @date,
    @counter.user_id
  )

  @period_label = @date.strftime("%B %d, %Y")
end

  def week
  start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
  end_date   = start_date.end_of_week
  @start_date = start_date

  @chart_data   = build_counter_chart_by_day(@counter.user_id, start_date, end_date)
  @user_charts  = build_single_user_pie(@counter.user_id, start_date, end_date)
  @loss_total   = calculate_loss_for_user(start_date, end_date, @counter.user_id)
  @period_label = "#{@counter.user_id} – #{start_date.strftime('%b %d')} – #{end_date.strftime('%b %d, %Y')}"
end

  def month
  date       = params[:month] ? Date.parse("#{params[:month]}-01") : Date.today
  start_date = date.beginning_of_month
  end_date   = date.end_of_month
  @date      = date

  @chart_data   = build_counter_chart_by_day(@counter.user_id, start_date, end_date)
  @user_charts  = build_single_user_pie(@counter.user_id, start_date, end_date)
  @loss_total   = calculate_loss_for_user(start_date, end_date, @counter.user_id)
  @period_label = "#{@counter.user_id} – #{date.strftime('%B %Y')}"
end

  def year
  @year    = params[:year] ? params[:year].to_i : Date.today.year
  fiscal_year_start = if params[:year]
                        Date.new(@year, 9, 1)
                      elsif Date.today.month < 9
                        Date.new(Date.today.year - 1, 9, 1)
                      else
                        Date.new(Date.today.year, 9, 1)
                      end

  start_date = fiscal_year_start
  end_date   = fiscal_year_start + 1.year - 1.day

  @chart_data   = build_counter_chart_by_month(@counter.user_id, start_date, end_date)
  @user_charts  = build_single_user_pie(@counter.user_id, start_date, end_date)
  @loss_total   = calculate_loss_for_user(start_date, end_date, @counter.user_id)
  @period_label = "#{@counter.user_id} – FY #{start_date.strftime('%b %Y')} – #{end_date.strftime('%b %Y')}"
end

  def life
  first_date = @store.trackers.minimum(:date) || Date.today
  last_date  = @store.trackers.maximum(:date) || Date.today

  @chart_data   = build_counter_chart_by_month(@counter.user_id, first_date, last_date)
  @user_charts  = build_single_user_pie(@counter.user_id, first_date, last_date)
  @loss_total   = calculate_loss_for_user(first_date, last_date, @counter.user_id)
  @period_label = "#{@counter.user_id} – All Time"
end

  #############################################################################################

  private
    # Use callbacks to share common setup or constraints between actions.



    #######################################################################

      def aggregated_pdf_counts_for_user(start_date, end_date, user_id)
    @store.pdf_imports
          .where(report_date: start_date..end_date)
          .sum { |import| import.user_counts[user_id].to_i }
  end

  def aggregated_tracker_counts_for_user(start_date, end_date, user_id)
    @store.trackers
          .where(date: start_date..end_date)
          .where(counter: user_id)
          .count
  end

  def calculate_loss_for_user(start_date, end_date, user_id)
    @store.trackers
          .where(date: start_date..end_date)
          .where(counter: user_id)
          .where.not(counted: nil)
          .where.not(sss_inv_count: nil)
          .where.not(price: nil)
          .sum("(counted - sss_inv_count) * price")
          .round(2)
  end

  def build_counter_chart_by_day(user_id, start_date, end_date)
    tracker_by_date = @store.trackers
                            .where(date: start_date..end_date)
                            .where(counter: user_id)
                            .group(:date)
                            .count

    pdf_by_date = @store.pdf_imports
                        .where(report_date: start_date..end_date)
                        .each_with_object(Hash.new(0)) do |import, hash|
                          hash[import.report_date] += import.user_counts[user_id].to_i
                        end

    (start_date..end_date).each_with_object({}) do |date, hash|
      t = tracker_by_date[date] || 0
      p = pdf_by_date[date] || 0
      hash[date.strftime("%b %d")] = percentage(t, p)
    end
  end

  def build_counter_chart_by_month(user_id, start_date, end_date)
    tracker_by_month = @store.trackers
                             .where(date: start_date..end_date)
                             .where(counter: user_id)
                             .group_by_month(:date, format: "%b %Y")
                             .count

    pdf_by_month = @store.pdf_imports
                         .where(report_date: start_date..end_date)
                         .each_with_object(Hash.new(0)) do |import, hash|
                           key = import.report_date.strftime("%b %Y")
                           hash[key] += import.user_counts[user_id].to_i
                         end

    all_keys = (tracker_by_month.keys + pdf_by_month.keys).uniq.sort_by { |k| Date.parse("01 #{k}") }
    all_keys.each_with_object({}) do |key, hash|
      t = tracker_by_month[key] || 0
      p = pdf_by_month[key] || 0
      hash[key] = percentage(t, p)
    end
  end

  def build_single_user_pie(user_id, start_date, end_date)
    pdf_count     = aggregated_pdf_counts_for_user(start_date, end_date, user_id)
    tracker_count = aggregated_tracker_counts_for_user(start_date, end_date, user_id)
    accurate      = [pdf_count - tracker_count, 0].max
    { user_id => { "Accurate" => accurate, "Inaccurate" => tracker_count } }
  end

  def set_counter
    @counter = Counter.find(params[:id] || params[:counter_id])
    @store   = @counter.store
  end

  def get_store
    @store = Store.find(params[:store_id])
  end

    # Only allow a list of trusted parameters through.
    def counter_params
      params.expect(counter: [ :user_id, :counter_cert_training, :store_id ])
    end
end
