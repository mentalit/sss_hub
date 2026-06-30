class Counter < ApplicationRecord
  belongs_to :store

  NO_CERT = [
    "440 ERROR", "AUTO", "DELAYED REPLEN",
    "DOMINANCE UNREGISTERED", "INCOMPLETE 390",
    "MISS-BINNED", "MISSING", "MISSING 310",
    "MISSING 310 Transfer", "Missing 310 transfer",
    "PACKAGING TRANSITION", "PICKING TIME ERROR",
    "SGF ERROR", "SLM ERROR", "SLM UNREGISTERED",
    "TIMING ERROR", "TRANSFER ERROR", "VASS ERROR", "ANFOR"
  ].freeze

  def no_cert?
    NO_CERT.include?(user_id.to_s.strip)
  end

  def expired_cert?
    counter_cert_training.blank? || counter_cert_training < 1.year.ago
  end

  def needs_red?
    !no_cert? && expired_cert?
  end
end