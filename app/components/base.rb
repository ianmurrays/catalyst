# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormFor
  include Phlex::Rails::Helpers::Translate
  include Phlex::Rails::Helpers::L
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StylesheetLinkTag
  include Phlex::Rails::Helpers::JavascriptImportmapTags

  # Register helpers that need access to Rails context
  register_value_helper :current_user
  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token
  register_value_helper :t
  register_value_helper :l

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
