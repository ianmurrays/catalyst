module TeamContext
  extend ActiveSupport::Concern

  included do
    before_action :require_team
    helper_method :team_scoped_path
  end

  # Placeholder helper to generate paths with team context.
  # In future phases this can prepend team slug or id to paths as needed.
  def team_scoped_path(path)
    path
  end
end
