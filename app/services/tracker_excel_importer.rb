# app/services/tracker_excel_importer.rb

require 'roo'

class TrackerExcelImporter
  HEADER_MAP = {
    'Date'                => :date,
    'ArtNum'              => :art_num,
    'Art name'            => :art_name,
    'BOH'                 => :boh,
    'Counter'             => :counter,
    'Counted'             => :counted,
    'Initial Diff'        => :initial_diff,
    'SSS Inv count'       => :sss_inv_count,
    'Price'               => :price,
    'Initial Loss'        => :initial_loss,
    'Diff after recount'  => :diff_after_recount,
    'Loss after recount'  => :loss_after_recount,
    'SLID_H'              => :slid_h,
    'Comment'             => :comment
  }.freeze

  def initialize(store, file)
    @store = store
    @file  = file
  end

  def call
    spreadsheet    = Roo::Spreadsheet.open(@file.path)
    header_row     = spreadsheet.row(1)

    validate_headers!(header_row)

    mapped_headers = header_row.map { |h| HEADER_MAP[h.to_s.strip] }

    imported_count = 0
    skipped_count  = 0

    (2..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      next if row.compact.empty?

      attributes = mapped_headers.each_with_index.each_with_object({}) do |(header, index), hash|
        next if header.nil?
        hash[header] = row[index]
      end

      if attributes[:art_num].blank?
        Rails.logger.warn "Skipped row #{i}: missing ArtNum"
        skipped_count += 1
        next
      end

      tracker = @store.trackers.new(
        date:               parse_date(attributes[:date]),
        art_num:            attributes[:art_num],
        art_name:           attributes[:art_name],
        boh:                to_integer(attributes[:boh]),
        counter:            attributes[:counter],
        counted:            to_integer(attributes[:counted]),
        initial_diff:       to_integer(attributes[:initial_diff]),
        sss_inv_count:      to_integer(attributes[:sss_inv_count]),
        price:              to_decimal(attributes[:price]),
        initial_loss:       to_decimal(attributes[:initial_loss]),
        diff_after_recount: to_integer(attributes[:diff_after_recount]),
        loss_after_recount: to_decimal(attributes[:loss_after_recount]),
        slid_h:             attributes[:slid_h],
        comment:            attributes[:comment]
      )

      if tracker.save
        imported_count += 1
      else
        skipped_count += 1
        Rails.logger.warn "Skipped row #{i}: #{tracker.errors.full_messages.join(', ')}"
      end
    end

    { imported: imported_count, skipped: skipped_count }
  end

  private

  def validate_headers!(header_row)
    normalized = header_row.map(&:to_s)
    missing    = HEADER_MAP.keys - normalized
    raise "Missing headers: #{missing.join(', ')}" if missing.any?
  end

  def parse_date(value)
    return value if value.is_a?(Date)
    return nil if value.blank?
    Date.parse(value.to_s)
  rescue
    nil
  end

  def to_integer(value)
    return nil if value.blank?
    value.to_i
  end

  def to_decimal(value)
    return nil if value.blank?
    BigDecimal(value.to_s)
  rescue
    nil
  end
end