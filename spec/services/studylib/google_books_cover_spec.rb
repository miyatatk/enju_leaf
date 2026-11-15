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
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  def stub_books(status:, body:, cache_control: "max-age=60")
    stub_request(:get, "https://www.googleapis.com/books/v1/volumes")
      .with(query: { "q" => "isbn:#{isbn}", "key" => key, "maxResults" => "5" })
      .to_return(status: status, body: body, headers: { "Cache-Control" => cache_control })
  end

  it "retrieves the matching cover without exposing the key" do
    stub = stub_books(status: 200, body: payload)
    url = described_class.new.image_url(isbn)

    expect(url).to eq(image_url)
    expect(url).not_to include(key)
    expect(stub).to have_been_requested.once
  end

  it "caches successful responses for the permitted duration" do
    stub = stub_books(status: 200, body: payload)
    first = described_class.new.image_url(isbn)
    second = described_class.new.image_url(isbn)
    expect(first).to eq(second)
    expect(stub).to have_been_requested.once
  end

  it "does not cache a response when caching is forbidden" do
    stub = stub_books(status: 200, body: payload, cache_control: "no-store")
    2.times { described_class.new.image_url(isbn) }
    expect(stub).to have_been_requested.twice
  end

  it "does not cache when Cache-Control has no max-age" do
    stub = stub_books(status: 200, body: payload, cache_control: "")
    2.times { described_class.new.image_url(isbn) }
    expect(stub).to have_been_requested.twice
  end

  it "does not cache quota failures" do
    stub = stub_books(status: 429, body: "{}")
    expect(described_class.new.image_url(isbn)).to be_nil
    expect(described_class.new.image_url(isbn)).to be_nil
    expect(stub).to have_been_requested.twice
  end

  it "returns nil for forbidden requests" do
    stub_books(status: 403, body: "{}")
    expect(described_class.new.image_url(isbn)).to be_nil
  end

  it "returns nil when an ISBN has no cover" do
    stub_books(status: 200, body: { items: [] }.to_json)
    expect(described_class.new.image_url(isbn)).to be_nil
  end

  it "rejects mismatched ISBNs" do
    wrong = payload.sub(isbn, "9784163909036")
    stub_books(status: 200, body: wrong)
    expect(described_class.new.image_url(isbn)).to be_nil
  end

  it "ignores untrusted image hosts" do
    stub_books(status: 200, body: payload.sub("books.google.com", "example.org"))
    expect(described_class.new.image_url(isbn)).to be_nil
  end

  it "ignores malformed items" do
    stub_books(status: 200, body: { items: [nil, {}, { volumeInfo: "invalid" }] }.to_json)
    expect(described_class.new.image_url(isbn)).to be_nil
  end

  it "converts HTTP image links to HTTPS" do
    stub_books(status: 200, body: payload.sub("https://books.google.com", "http://books.google.com"))
    expect(described_class.new.image_url(isbn)).to start_with("https://books.google.com")
  end
end
