require "net/http"
require "digest"

module Studylib
  # Looks up Google Books cover URLs on the server, without exposing the API key.
  # Only caches API content for the max-age permitted by its Cache-Control header.
  class GoogleBooksCover
    API_HOST = "www.googleapis.com"
    ALLOWED_IMAGE_HOSTS = %w[books.google.com books.google.co.jp books.googleusercontent.com].freeze
    MAX_CACHE_AGE = 6.hours

    def initialize(library_group = LibraryGroup.site_config)
      @library_group = library_group
    end

    def image_url(raw_isbn)
      isbn = normalize_isbn(raw_isbn)
      return nil unless isbn

      key = GoogleBooksApiKey.new(@library_group).value
      return nil if key.blank?

      cache_key = "studylib/cover/v1/#{Digest::SHA256.hexdigest(key).first(16)}/#{isbn}"
      cached = Rails.cache.read(cache_key)
      return cached["url"] if cached.is_a?(Hash) && cached.key?("url")

      response = request_google(isbn, key)
      return nil unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      url = Array(payload["items"]).filter_map { |item| matched_cover(item, isbn) }.first

      max_age = cache_max_age(response["cache-control"])
      Rails.cache.write(cache_key, { "url" => url }, expires_in: max_age) if max_age.positive?
      url
    rescue JSON::ParserError, SocketError, Timeout::Error, IOError, OpenSSL::SSL::SSLError,
           ActiveSupport::MessageEncryptor::InvalidMessage => e
      Rails.logger.warn("StudyLib Google Books cover lookup failed: #{e.class}")
      nil
    end

    private

    def normalize_isbn(value)
      isbn = value.to_s.upcase.delete(" -")
      return isbn if isbn.match?(/\A\d{13}\z/) || isbn.match?(/\A\d{9}[0-9X]\z/)

      nil
    end

    def request_google(isbn, key)
      query = URI.encode_www_form(q: "isbn:#{isbn}", key: key, maxResults: 5)
      uri = URI::HTTPS.build(host: API_HOST, path: "/books/v1/volumes", query: query)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
        http.get(uri.request_uri)
      end
    end

    def matched_cover(item, isbn)
      return nil unless item.is_a?(Hash)

      info = item["volumeInfo"]
      return nil unless info.is_a?(Hash)

      identifiers = Array(info["industryIdentifiers"])
      return nil unless identifiers.any? { |entry| entry.is_a?(Hash) && normalize_isbn(entry["identifier"]) == isbn }

      image_links = info["imageLinks"] || {}
      url = image_links["thumbnail"] || image_links["smallThumbnail"]
      return nil unless url.is_a?(String)

      uri = URI.parse(url)
      return nil unless uri.is_a?(URI::HTTP) && ALLOWED_IMAGE_HOSTS.include?(uri.host) && uri.userinfo.nil? && uri.port.in?([ 80, 443 ])

      # Google Books sometimes returns http: imageLinks; request the same host over HTTPS.
      uri.scheme = "https"
      uri.port = 443
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def cache_max_age(value)
      return 0 if value.blank? || value.match?(/(?:no-store|no-cache)/i)

      match = value.match(/(?:\A|,)\s*(?:s-maxage|max-age)=(\d+)/i)
      return 0 unless match

      [match[1].to_i, MAX_CACHE_AGE.to_i].min
    end
  end
end
