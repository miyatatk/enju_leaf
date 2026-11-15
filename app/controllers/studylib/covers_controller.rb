module Studylib
  class CoversController < ApplicationController
    before_action :skip_authorization

    def show
      url = GoogleBooksCover.new.image_url(params[:isbn])
      response.headers["Cache-Control"] = "no-store"

      if url.present?
        redirect_to url, allow_other_host: true
      else
        redirect_to helpers.asset_path("unknown_resource.png")
      end
    end
  end
end
