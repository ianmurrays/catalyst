# frozen_string_literal: true

class Views::Base < Components::Base
  # The `Views::Base` is an abstract class for all your views.

  # By default, it inherits from `Components::Base`, but you
  # can change that to `Phlex::HTML` if you want to keep views and
  # components independent.

  register_value_helper :current_user
  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token
  register_value_helper :form_with
  register_output_helper :form_with
end
