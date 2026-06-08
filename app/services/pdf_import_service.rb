require "pdf-reader"

class PdfImportService
  # Standalone user ID line: must contain at least one digit
  # (pure-alpha words on their own are article name fragments like DRACAENA)
  STANDALONE_USER        = /\A\s*([A-Z][A-Z0-9]*\d[A-Z0-9]*)\s*\z/
  PAT_WITH_USER          = /\d{8}.*?(?:Sales|Storage)\s+(?:(?!\d{2}\s)\S+\s+)?(\d{2})\s+\S+\s+(?:\S+\s+)?([A-Z][A-Z0-9]+?)(?:\s+\d{2}:\d{2}|\d{2}:\d{2})/
  PAT_NO_TIME            = /\d{8}.*?(?:Sales|Storage)\s+(?:(?!\d{2}\s)\S+\s+)?(\d{2})\s+\S+\s+([A-Z][A-Z0-9]+)\s+\d+\s*\z/
  PAT_NO_USER            = /\d{8}.*?(?:Sales|Storage)\s+(?:(?!\d{2}\s)\S+\s+)?(\d{2})\s+\S+\s+(?:\S+\s+)?\d{2}:\d{2}/
  STRIP_CHECK_USER       = /\s*\(§\).*\z/
  STRIP_AFTER_FIRST_USER = /(\d{2}:\d{2}\s+\S+)\s+\d+\s+[A-Z][A-Z0-9]+.*\z/

  def initialize(file)
    @file = file
  end

  def call
    reader       = PDF::Reader.new(path_or_io)
    date         = extract_date(reader.pages.first.text)
    pa_counts    = Hash.new(0)
    user_counts  = Hash.new(0)
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

  def clean_line(line)
    line.sub(STRIP_CHECK_USER, "").sub(STRIP_AFTER_FIRST_USER, '\1')
  end

  def parse_line(line, pending_user)
    stripped = line.strip
    return [nil, nil, pending_user] if stripped.empty?
    return [nil, nil, pending_user] if stripped.match?(/Comment|Total/)

    # Standalone user ID — must contain a digit to exclude article name fragments
    if (su = STANDALONE_USER.match(stripped)) && !stripped.match?(/\d{8}/)
      return [nil, nil, su[1]]
    end

    cleaned = clean_line(line)

    if (m = PAT_WITH_USER.match(cleaned))
      return [m[1], m[2], nil]
    end

    if (m = PAT_NO_TIME.match(cleaned))
      return [m[1], m[2], nil]
    end

    if (m = PAT_NO_USER.match(cleaned)) && pending_user
      return [m[1], pending_user, nil]
    end

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