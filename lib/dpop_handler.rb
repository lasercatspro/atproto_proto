# Handler for DPoP (Demonstrating Proof-of-Possession) protocol implementation
class DpopHandler
  class DpopError < StandardError; end

  # Initialize a new DPoP handler
  # @param private_key [OpenSSL::PKey::EC, nil] Optional private key for signing tokens
  def initialize(private_key = nil)
    @private_key = private_key || generate_private_key
    @current_nonce = nil
    @nonce_mutex = Mutex.new
    @token_mutex = Mutex.new
  end

  # Generates a DPoP token for a request
  # @param http_method [String] The HTTP method of the request
  # @param url [String] The target URL of the request
  # @param nonce [String, nil] Optional nonce value
  # @return [String] The generated DPoP token
  def generate_token(http_method, url, nonce = @current_nonce)
    @token_mutex.synchronize do
      create_dpop_token(http_method, url, nonce)
    end
  end

  # Updates the current nonce from response headers
  # @param response [Net::HTTPResponse] Response containing dpop-nonce header
  def update_nonce(response)
    new_nonce = response.to_hash.dig("dpop-nonce", 0)
    @nonce_mutex.synchronize do
      @current_nonce = new_nonce if new_nonce
    end
  end

  # Makes an HTTP request with DPoP handling,
  # when no nonce is used for the first try, takes it from the response and retry
  # @param uri [String] The target URI
  # @param method [String] The HTTP method
  # @param headers [Hash] Optional request headers
  # @param body [Hash, nil] Optional request body
  # @return [Net::HTTPResponse] The HTTP response
  # @raise [DpopError] If the request fails
  def make_request(uri, method, headers: {}, body: nil)
    uri = URI(uri)
    # There would probably be something more clever to do here
    response = attempt_request(uri, method, headers, body)

    return response if response.is_a?(Net::HTTPSuccess)

    update_nonce(response)
    response = attempt_request(uri, method, headers, body)

    return response if response.is_a?(Net::HTTPSuccess)

    raise DpopError, "DPoP request failed: #{response.body}"
  end

  private

  def attempt_request(uri, method, headers, body)
    dpop_token = generate_token(method.to_s.upcase, uri.to_s)
    request = build_request(method, uri, headers.merge("DPoP" => dpop_token))
    request.body = body.to_json if body

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end

  HTTP_METHODS = {
    "GET" => Net::HTTP::Get,
    "POST" => Net::HTTP::Post,
    "PUT" => Net::HTTP::Put,
    "DELETE" => Net::HTTP::Delete
  }.freeze

  def build_request(method, uri, headers)
    method = method.to_s.upcase
    request_class = HTTP_METHODS[method] or raise DpopError, "Unsupported HTTP method: #{method}"

    request_class.new(uri).tap do |request|
      headers.each { |k, v| request[k] = v }
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
    end
  end

  def generate_private_key
    OpenSSL::PKey::EC.generate("prime256v1").tap(&:check_key)
  end

  # Creates a DPoP token with the specified parameters, encoded by jwk
  def create_dpop_token(http_method, target_uri, nonce = nil)
    jwk = create_jwk_from_public_key(@private_key.public_key)

    payload = {
      jti: SecureRandom.hex(16),
      htm: http_method,
      htu: target_uri,
      iat: Time.now.to_i,
      exp: Time.now.to_i + 120
    }

    payload[:nonce] = nonce if nonce

    JWT.encode(payload, @private_key, "ES256", { typ: "dpop+jwt", alg: "ES256", jwk: })
  end

  # Creates a Json Web Key from public key
  def create_jwk_from_public_key(public_key)
    bn = public_key.to_bn
    x_coord = OpenSSL::BN.new(bn.to_s(16)[2..65], 16)
    y_coord = OpenSSL::BN.new(bn.to_s(16)[66..-1], 16)

    {
      kty: "EC",
      crv: "P-256",
      x: Base64.urlsafe_encode64(x_coord.to_s(2), padding: false),
      y: Base64.urlsafe_encode64(y_coord.to_s(2), padding: false)
    }
  end
end
