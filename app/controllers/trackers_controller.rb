class TrackersController < ApplicationController
  before_action :set_store

  def index
    @trackers = @store.trackers.order(created_at: :desc)
  end

  def new
  end

  def create
    if params[:file].blank?
      redirect_to new_store_tracker_path(@store),
                  alert: 'Please select a file.'
      return
    end

    begin
      TrackerExcelImporter.new(@store, params[:file]).call

      redirect_to store_trackers_path(@store),
                  notice: 'Excel uploaded successfully.'
    rescue => e
      Rails.logger.error e.message

      redirect_to new_store_tracker_path(@store),
                  alert: "Upload failed: #{e.message}"
    end
  end

  private

  def set_store
    @store = Store.find(params[:store_id])
  end
end