# frozen_string_literal: true

class TimezoneService
  def self.available_timezones
    ActiveSupport::TimeZone.all
  end

  def self.timezone_options
    available_timezones.map { |tz| [ tz.to_s, tz.name ] }
  end

  def self.grouped_timezone_options
    available_timezones.group_by(&:utc_offset).sort.map do |offset, zones|
      [ format_offset(offset), zones.map { |z| [ z.to_s, z.name ] } ]
    end
  end

  def self.valid_timezone?(identifier)
    return false if identifier.blank?
    ActiveSupport::TimeZone[identifier].present?
  end

  def self.find_timezone(identifier)
    return nil if identifier.blank?
    ActiveSupport::TimeZone[identifier]
  end

  private

  def self.format_offset(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours >= 0
      if minutes.zero?
        format("UTC+%02d:00", hours)
      else
        format("UTC+%02d:%02d", hours, minutes)
      end
    else
      if minutes.zero?
        format("UTC%03d:00", hours)
      else
        format("UTC%03d:%02d", hours, minutes.abs)
      end
    end
  end
end
