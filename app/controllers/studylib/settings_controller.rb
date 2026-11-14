module Studylib
  class SettingsController < ApplicationController
    before_action :authenticate_user!

    def show
      authorize :settings, :show?, policy_class: Studylib::SettingsPolicy
      @title = t("studylib.settings.title")
      @google_books_key_configured = GoogleBooksApiKey.new(@library_group).configured?
    end

    def update
      authorize :settings, :update?, policy_class: Studylib::SettingsPolicy

      key = params.fetch(:settings, {}).permit(:google_books_api_key, :remove_google_books_api_key)
      api_key = key[:google_books_api_key].to_s
      remove = key[:remove_google_books_api_key] == "1"

      if remove && api_key.present?
        return redirect_to studylib_settings_path, alert: t("studylib.settings.key_conflict")
      end

      storage = GoogleBooksApiKey.new(@library_group)
      if remove
        storage.clear!
      elsif api_key.present?
        storage.save!(api_key)
      else
        return redirect_to studylib_settings_path, alert: t("studylib.settings.no_change")
      end

      redirect_to studylib_settings_path, notice: t("studylib.settings.saved")
    rescue ArgumentError
      redirect_to studylib_settings_path, alert: t("studylib.settings.invalid_key")
    end
  end
end
