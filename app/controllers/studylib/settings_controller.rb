module Studylib
  class SettingsController < ApplicationController
    before_action :authenticate_user!

    def show
      authorize :settings, :show?, policy_class: Studylib::SettingsPolicy
      @title = t("studylib.settings.title")
    end
  end
end
