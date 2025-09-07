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
    handle_avatar_removal if params[:user][:remove_avatar] == "1"

    if @user.update(user_params_without_avatar_removal)
      redirect_to profile_path, notice: t("flash.profile.updated")
    else
      render Views::Profile::Edit.new(user: @user, errors: @user.errors), status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    # Email is always provided by authentication provider and cannot be updated
    params.require(:user).permit(
      :display_name,
      :bio,
      :phone,
      :avatar,
      :remove_avatar,
      { preferences: [ :timezone, :language, { email_notifications: [ :profile_updates, :security_alerts, :feature_announcements ] } ] }
    )
  end

  def user_params_without_avatar_removal
    user_params.except(:remove_avatar)
  end

  def handle_avatar_removal
    @user.avatar.purge if @user.avatar.attached?
  end
end
