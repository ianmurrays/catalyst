# frozen_string_literal: true

# Configure Audited gem
Audited.config do |config|
  # Use the standard current_user method
  config.current_user_method = :current_user
end
