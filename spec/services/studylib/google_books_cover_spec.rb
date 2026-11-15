require "rails_helper"
require "webmock/rspec"

RSpec.describe Studylib::GoogleBooksCover do
  fixtures :all

  let(:isbn) { "9784163909035" }
  let(:key) { "AIza" + "A" * 35 }
  let(:image_url) { "https://books.google.com/books/content?id=abc&printsec=frontcover" }
  let(:payload) do
    {
      items: [
        { volumeInfo: {
          industryIdentifiers: [ { type: "ISBN_13", identifier: isbn } ],
          imageLinks: { thumbnail: image_url }
        } }
      ]
    }.to_json
  end

  before do
    Studylib::GoogleBooksApiKey.new(LibraryGroup.site_config).save!(key)
  end

  it "retrieves a matching cover without exposing the key in the returned URL" do
    stub = stub_request(:get, "https://www.googleapis.com/books/v1/volumes")
      .with(query: { "q" => "isbn:#{isbn}", "key" => key, "maxResults" => "5" })
      .to_return(status: 200, body: payload, headers: { "Cache-Control" => "max-age=60" })

    expect(described_class.new.image_url(isbn)).to eq(image_url)
    expect(described_class.new.image_url(isbn)).to eq(image_url)
    expect(stub).to have_been_requested.once
  end

  it "ignores images from other hosts" do
    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 200, body: payload.sub("books.google.com", "example.org"))

    expect(described_class.new.image_url(isbn)).to be_nil
  end

  it "uses the fallback when quota is exhausted" do
    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 429, body: "{}")
    expect(described_class.new.image_url(isbn)).to be_nil
  end
end
