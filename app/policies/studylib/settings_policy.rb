module Studylib
  class SettingsPolicy < ApplicationPolicy
    def show?
      !!user&.has_role?("Administrator")
    end

    def update?
      show?
    end
  end
end
