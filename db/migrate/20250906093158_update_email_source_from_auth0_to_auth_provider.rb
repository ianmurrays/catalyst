class UpdateEmailSourceFromAuth0ToAuthProvider < ActiveRecord::Migration[8.0]
  def up
    User.where(email_source: "auth0").update_all(email_source: "auth_provider")
  end

  def down
    User.where(email_source: "auth_provider").update_all(email_source: "auth0")
  end
end
