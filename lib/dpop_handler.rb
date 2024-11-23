class DpopHandler
  class DpopError < StandardError; end

  def initialize(private_key = nil)
    @private_key = private_key || generate_private_key
    @current_nonce = nil
    @nonce_mutex = Mutex.new
    @token_mutex = Mutex.new
  end

  # Génère un token DPoP pour une requête
  def generate_token(http_method, url, nonce = @current_nonce)
    @token_mutex.synchronize do
      create_dpop_token(http_method, url, nonce)
    end
  end

  # Met à jour le nonce depuis les headers de réponse
  def update_nonce(response_headers)
    new_nonce = response_headers["dpop-nonce"]
    @nonce_mutex.synchronize do
      @current_nonce = new_nonce if new_nonce
    end
  end

  # Effectue une requête HTTP avec gestion du DPoP
  def make_request(uri, method, headers: {}, body: nil)
    retries = 0
    begin
      uri = URI(uri)
      dpop_token = generate_token(method.to_s.upcase, uri.to_s)

      # Prépare la requête
      request = build_request(method, uri, headers.merge("DPoP" => dpop_token))
      request.body = body.to_json if body

      # Exécute la requête
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      update_nonce(response)
      response
    rescue => e
      if retries < 1 && e.response&.headers&.dig("dpop-nonce")
        retries += 1
        update_nonce(e.response.headers)
        retry
      end
      raise DpopError, "DPoP request failed: #{e.message}"
    end
  end

  private

  def build_request(method, uri, headers)
    request_class = case method.to_s.upcase
    when "GET" then Net::HTTP::Get
    when "POST" then Net::HTTP::Post
    when "PUT" then Net::HTTP::Put
    when "DELETE" then Net::HTTP::Delete
    else
      raise DpopError, "Unsupported HTTP method: #{method}"
    end

    request = request_class.new(uri)
    headers.each { |k, v| request[k] = v }
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request
  end

  def generate_private_key
    OpenSSL::PKey::EC.generate("prime256v1").tap(&:check_key)
  end

  def create_dpop_token(http_method, audience, nonce = nil)
    point = @private_key.public_key
    bn = point.to_bn

    x_coord = OpenSSL::BN.new(bn.to_s(16)[2..65], 16)
    y_coord = OpenSSL::BN.new(bn.to_s(16)[66..-1], 16)

    jwk = {
      kty: "EC",
      crv: "P-256",
      x: Base64.urlsafe_encode64(x_coord.to_s(2), padding: false),
      y: Base64.urlsafe_encode64(y_coord.to_s(2), padding: false)
    }

    payload = {
      jti: SecureRandom.hex(16),
      htm: http_method,
      htu: audience,
      iat: Time.now.to_i,
      exp: Time.now.to_i + 120
    }

    payload[:nonce] = nonce if nonce

    JWT.encode(
      payload,
      @private_key,
      "ES256",
      {
        typ: "dpop+jwt",
        alg: "ES256",
        jwk: jwk
      }
    )
  end
end
