require "openssl"
require "jwt"
require "base64"

module AtprotoKeys
  class << self
    def generate_key_pair
      key = OpenSSL::PKey::EC.generate("prime256v1")
      # Store both private and public key information
      private_key = key
      public_key = key.public_key

      # Get the coordinates for JWK
      bn = public_key.to_bn(:uncompressed)
      raw_bytes = bn.to_s(2)
      coord_bytes = raw_bytes[1..-1]
      byte_length = coord_bytes.length / 2

      x_coord = coord_bytes[0, byte_length]
      y_coord = coord_bytes[byte_length, byte_length]

      jwk = {
        kty: "EC",
        crv: "P-256",
        x: Base64.urlsafe_encode64(x_coord, padding: false),
        y: Base64.urlsafe_encode64(y_coord, padding: false),
        use: "sig",
        alg: "ES256",
        kid: SecureRandom.uuid
      }.freeze

      [ private_key, jwk ]
    end

    def current_private_key
      @current_private_key ||= load_or_generate_keys.first
    end

    def current_jwk
      @current_jwk ||= load_or_generate_keys.last
    end

    private

    def load_or_generate_keys
      key_path = Rails.root.join("config", "atproto_private_key.pem")
      jwk_path = Rails.root.join("config", "atproto_jwk.json")

      if File.exist?(key_path) && File.exist?(jwk_path)
        private_key = OpenSSL::PKey::EC.new(File.read(key_path))
        jwk = JSON.parse(File.read(jwk_path), symbolize_names: true)
        [ private_key, jwk ]
      else
        private_key, jwk = generate_key_pair
        File.write(key_path, private_key.to_pem)
        File.write(jwk_path, JSON.pretty_generate(jwk))
        [ private_key, jwk ]
      end
    end
  end
end
