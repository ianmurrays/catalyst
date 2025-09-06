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
    params.require(:user).permit(
      :display_name,
      :bio,
      :phone,
      preferences: [ :timezone, :language, { email_notifications: [ :profile_updates, :security_alerts, :feature_announcements ] } ]
    )
  end
end
