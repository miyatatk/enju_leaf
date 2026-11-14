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

  describe "PATCH /studylib/settings" do
    let(:key) { "AIza" + "A" * 35 }

    it "blocks guests and librarians" do
      patch studylib_settings_path, params: { settings: { google_books_api_key: key } }
      expect(response).to redirect_to(new_user_session_url)

      sign_in users(:librarian1)
      patch studylib_settings_path, params: { settings: { google_books_api_key: key } }
      expect(response).to have_http_status(:forbidden)
      expect(Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config)).not_to be_configured
    end

    it "encrypts the key without displaying its value" do
      sign_in users(:admin)
      patch studylib_settings_path, params: { settings: { google_books_api_key: key } }
      expect(response).to redirect_to(studylib_settings_path)

      store = Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config.reload)
      expect(store).to be_configured
      expect(store.value).to eq(key)
      expect(LibraryGroup.site_config.settings.values.join).not_to include(key)

      get studylib_settings_path
      expect(response.body).to include("password")
      expect(response.body).not_to include(key)
    end

    it "preserves the key when submitted blank and removes it only on request" do
      sign_in users(:admin)
      store = Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config)
      store.save!(key)

      patch studylib_settings_path, params: { settings: { google_books_api_key: "" } }
      expect(Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config.reload).value).to eq(key)

      patch studylib_settings_path, params: { settings: { remove_google_books_api_key: "1" } }
      expect(Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config.reload)).not_to be_configured
    end

    it "rejects malformed API keys" do
      sign_in users(:admin)
      patch studylib_settings_path, params: { settings: { google_books_api_key: "not a valid key" } }
      expect(Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config.reload)).not_to be_configured
    end
  end
end
