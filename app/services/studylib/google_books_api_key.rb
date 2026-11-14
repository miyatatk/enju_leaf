module Studylib
  # Stores the API key encrypted in the existing LibraryGroup settings JSONB column.
  # The encryption key is derived from the application's existing secret_key_base.
  class GoogleBooksApiKey
    STORAGE_KEY = "studylib_google_books_api_key_encrypted".freeze

    def initialize(library_group = LibraryGroup.site_config)
      @library_group = library_group
    end

    def configured?
      @library_group.settings[STORAGE_KEY].present?
    end

    def value
      ciphertext = @library_group.settings[STORAGE_KEY]
      return nil if ciphertext.blank?

      encryptor.decrypt_and_verify(ciphertext)
    end

    def save!(key)
      key = key.to_s.strip
      raise ArgumentError, "API key must contain between 20 and 256 characters" unless key.length.between?(20, 256)
      raise ArgumentError, "API key contains unsupported characters" unless key.match?(/\A[A-Za-z0-9_-]+\z/)

      @library_group.update!(
        settings: @library_group.settings.merge(STORAGE_KEY => encryptor.encrypt_and_sign(key))
      )
    end

    def clear!
      @library_group.update!(settings: @library_group.settings.except(STORAGE_KEY))
    end

    private

    def encryptor
      secret = Rails.application.key_generator.generate_key("studylib/google_books_api_key", 32)
      ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm")
    end
  end
end
