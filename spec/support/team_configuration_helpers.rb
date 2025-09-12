# frozen_string_literal: true

module TeamConfigurationHelpers
  def with_team_creation_allowed(allowed = true)
    original = Rails.configuration.allow_team_creation
    Rails.configuration.allow_team_creation = allowed
    yield
  ensure
    Rails.configuration.allow_team_creation = original
  end
end

RSpec.configure do |config|
  config.include TeamConfigurationHelpers
end
