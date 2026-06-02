# app/services/pdf_import_service.rb
#
# Add to Gemfile:  gem "pdf-reader"
# Then:           bundle install
#
# Pure Ruby — works on Linux, macOS, and Windows.

require "pdf-reader"

class PdfImportService
  # pdf-reader produces three kinds of article rows:
  #
  # 1. User on a SEPARATE line above the data line (ALVEN14 case):
  #    "                             ALVEN14"
  #    "   00456306  GUNNARED...  Sales  700000  01  3        04:22  3"
  #
  # 2. User jammed against time with no space (ROKRA28 case):
  #    "   10539066  ...  Sales  M12D01  12  48 ROKRA2805:06  48"
  #
  # 3. Normal spacing:
  #    "   00586336  ...  Sales  152300  03  39 EKIGB 04:20  3"

  # A line that is only a User ID (letters+digits, starts with letter, 4+ chars, no article number)
  STANDALONE_USER = /\A\s*([A-Z][A-Z0-9]{3,})\s*\z/

  # User present with or without space before time HH:MM
  PAT_WITH_USER = /
    \d{8}.*?(?:Sales|Storage)\s+  # article + row type
    (?:(?!\d{2}[\s$])\S+\s+)?     # optional location ID
    (\d{2})\s+                     # PA
    \S+\s+                         # qty1
    (?:\S+\s+)?                    # qty2 (Storage only, optional)
    ([A-Z][A-Z0-9]+?)              # User ID (non-greedy for jammed case)
    (?:\s+\d{2}:\d{2}|\d{2}:\d{2}) # time with or without leading space
  /x

  # User present but NO time (AUTO entries end with user + final count)
  PAT_NO_TIME = /
    \d{8}.*?(?:Sales|Storage)\s+
    (?:(?!\d{2}[\s$])\S+\s+)?
    (\d{2})\s+
    \S+\s+
    ([A-Z][A-Z0-9]+)
    \s+\d+\s*\z
  /x

  # User is absent from this line (was on the line above as a standalone)
  PAT_NO_USER = /
    \d{8}.*?(?:Sales|Storage)\s+
    (?:(?!\d{2}[\s$])\S+\s+)?
    (\d{2})\s+
    \S+\s+
    (?:\S+\s+)?
    \d{2}:\d{2}
  /x

  def initialize(file)
    @file = file
  end

  def call
    reader      = PDF::Reader.new(path_or_io)
    date        = extract_date(reader.pages.first.text)
    pa_counts   = Hash.new(0)
    user_counts = Hash.new(0)
    pending_user = nil

    reader.pages.each do |page|
      page.text.each_line do |line|
        pa, user, pending_user = parse_line(line, pending_user)
        next unless pa

        pa_counts[pa]    += 1
        user_counts[user] += 1
      end
    end

    {
      date:        date,
      pa_counts:   pa_counts.sort.to_h,
      user_counts: user_counts.sort.to_h,
      error:       nil
    }
  rescue => e
    { date: nil, pa_counts: {}, user_counts: {}, error: e.message }
  end

  private

  def parse_line(line, pending_user)
    stripped = line.strip
    return [nil, nil, pending_user] if stripped.empty?
    return [nil, nil, pending_user] if stripped.match?(/Comment|Total/)

    # Standalone user ID line — store it for the next article line
    if (su = STANDALONE_USER.match(stripped)) && !stripped.match?(/\d{8}/)
      return [nil, nil, su[1]]
    end

    # User present with timestamp (normal or jammed)
    if (m = PAT_WITH_USER.match(line))
      return [m[1], m[2], nil]
    end

    # User present but no timestamp (AUTO)
    if (m = PAT_NO_TIME.match(line))
      return [m[1], m[2], nil]
    end

    # No user on this line — use pending from previous line
    if (m = PAT_NO_USER.match(line)) && pending_user
      return [m[1], pending_user, nil]
    end

    # Not an article row — preserve pending_user only if no article number present
    next_pending = stripped.match?(/\d{8}/) ? nil : pending_user
    [nil, nil, next_pending]
  end

  def path_or_io
    @file.respond_to?(:path) ? @file.path : StringIO.new(@file.read)
  end

  def extract_date(text)
    m = text.match(/Created:\s*(\d{4}-\d{2}-\d{2})/)
    m ? m[1] : nil
  end
end