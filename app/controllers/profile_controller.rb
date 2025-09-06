class ProfileController < ApplicationController
  include Secured

  before_action :set_user

  def show
    render Views::Profile::Show.new(user: @user)
  end

  def edit
    render Views::Profile::Edit.new(user: @user)
  end

  def update
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profile updated successfully!"
    else
      render Views::Profile::Edit.new(user: @user, errors: @user.errors), status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    permitted_params = [
      :display_name,
      :bio,
      :phone,
      { preferences: [ :timezone, :language, { email_notifications: [ :profile_updates, :security_alerts, :feature_announcements ] } ] }
    ]

    # Only allow email updates for manually-entered emails, not authentication provider emails
    permitted_params << :email unless @user.auth_provider_email?

    params.require(:user).permit(*permitted_params)
  end
end
