class Auth0Controller < ApplicationController
  def callback
    # OmniAuth stores the information returned from Auth0 and the IdP in request.env['omniauth.auth'].
    # In this code, you will pull the raw_info supplied from the id_token and assign it to the session.
    # Refer to https://github.com/auth0/omniauth-auth0/blob/master/EXAMPLES.md#example-of-the-resulting-authentication-hash for complete information on 'omniauth.auth' contents.
    auth_info = request.env["omniauth.auth"]
    raw_info = auth_info["extra"]["raw_info"]

    begin
      # Attempt to create or find user - this will raise an error if email is missing
      User.find_or_create_from_auth_provider(raw_info)

      # Only set session if user creation succeeds
      session[:userinfo] = raw_info

      # Redirect to the URL they were trying to access or home
      redirect_url = session.delete(:return_to) || "/"
      redirect_to redirect_url
    rescue ArgumentError => e
      # Email is missing from provider
      Rails.logger.error "Authentication failed: #{e.message}"
      render Views::Auth0::Failure.new(error_msg: e.message), status: :unprocessable_content
    rescue => e
      # Other authentication errors
      Rails.logger.error "Authentication error: #{e.message}"
      error_msg = t("flash.auth.login_failed")
      render Views::Auth0::Failure.new(error_msg: error_msg), status: :unprocessable_content
    end
  end

  def failure
    # Handles failed authentication -- Show a failure page (you can also handle with a redirect)
    error_msg = request.params["message"] || t("flash.auth.login_failed")
    Rails.logger.error "Authentication failure: #{error_msg}"
    render Views::Auth0::Failure.new(error_msg: error_msg)
  end

  def logout
    reset_session
    redirect_to logout_url, allow_other_host: true
  end

  private

  def logout_url
    request_params = {
      returnTo: root_url,
      client_id: Rails.application.credentials.auth0.client_id
    }

    URI::HTTPS.build(host: Rails.application.credentials.auth0.domain, path: "/v2/logout", query: request_params.to_query).to_s
  end
end
