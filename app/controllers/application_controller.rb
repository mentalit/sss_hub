class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def percentage(tracker_count, pdf_total)
    return 0 if pdf_total.zero?
    ((tracker_count.to_f / pdf_total) * 100).round(2)
  end

end
