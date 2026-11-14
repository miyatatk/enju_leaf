require "rails_helper"

RSpec.describe "StudyLib extension settings", type: :request do
  fixtures :all

  describe "GET /studylib/settings" do
    it "redirects guests to sign in" do
      get studylib_settings_path
      expect(response).to redirect_to(new_user_session_url)
    end

    it "returns forbidden for ordinary users" do
      sign_in users(:user1)
      get studylib_settings_path
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for librarians" do
      sign_in users(:librarian1)
      get studylib_settings_path
      expect(response).to have_http_status(:forbidden)
    end

    it "allows administrators to view the settings page" do
      sign_in users(:admin)
      get studylib_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("StudyLib extension settings").or include("StudyLib拡張設定")
    end

    it "shows the menu link only to administrators" do
      sign_in users(:admin)
      get page_configuration_path
      expect(response.body).to include(studylib_settings_path)
    end

    it "does not show the menu link to librarians" do
      sign_in users(:librarian1)
      get page_configuration_path
      expect(response.body).not_to include(studylib_settings_path)
    end
  end
end
