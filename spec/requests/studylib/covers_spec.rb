require "rails_helper"

RSpec.describe "StudyLib Google Books covers", type: :request do
  fixtures :all

  it "redirects to the fallback image when the API key is not configured" do
    get studylib_cover_path(isbn: "9784163909035")
    expect(response).to have_http_status(:found)
    expect(response.location).to include("unknown_resource")
  end

  it "rejects invalid ISBNs without a Google Books API request" do
    get studylib_cover_path(isbn: "invalid-isbn")
    expect(response).to have_http_status(:found)
    expect(response.location).to include("unknown_resource")
  end
end
