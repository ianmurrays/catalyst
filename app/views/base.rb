# frozen_string_literal: true

class Views::Base < Components::Base
  # The `Views::Base` is an abstract class for all your views.

  # By default, it inherits from `Components::Base`, but you
  # can change that to `Phlex::HTML` if you want to keep views and
  # components independent.

  PageInfo = Data.define(:title, :description)

  register_value_helper :current_user
  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token
  register_value_helper :form_with
  register_output_helper :form_with
  register_value_helper :t
  register_value_helper :l

  def around_template
    render layout.new(page_info) do
      super
    end
  end

  def page_info
    PageInfo.new(
      title: page_title,
      description: page_description
    )
  end

  def page_title
    t("application.name")
  end

  def page_description
    nil
  end

  def layout
    Components::Layout::Application
  end
end
