class AtprotoClient
  class TokenExpiredError < StandardError; end

  def initialize(access_token, refresh_token, dpop_handler = nil)
    @access_token = access_token
    @refresh_token = refresh_token
    @dpop_handler = dpop_handler || DpopHandler.new
    @token_mutex = Mutex.new
    setup_client
  end

  def setup_client
    @client = Faraday.new do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def make_api_request(method, url, params: {}, body: nil)
    retries = 0
    begin
      uri = URI(url)
      uri.query = URI.encode_www_form(params) if params.any?

      response = @dpop_handler.make_request(
        uri.to_s,
        method,
        headers: { "Authorization" => "Bearer #{@access_token}" },
        body: body
      )

      handle_response(response)
    rescue TokenExpiredError => e
      if retries.zero? && @refresh_token
        retries += 1
        refresh_access_token!
        retry
      else
        raise e
      end
    end
  end

  private

  def handle_response(response)
    # Net::HTTP utilise response.code directement
    case response.code.to_i
    when 401
      body = JSON.parse(response.body)
      raise TokenExpiredError if body["error"] == "token_expired"
      raise StandardError, "Unauthorized: #{body["error"]}"
    when 200..299
      JSON.parse(response.body)
    else
      raise StandardError, "Request failed: #{response.code} - #{response.body}"
    end
  end

    def refresh_access_token!
        @token_mutex.synchronize do
          refresh_dpop = DpopHandler.new

          response = refresh_dpop.make_request(
            "#{base_url}/xrpc/com.atproto.server.refreshSession",
            :post,
            body: { refresh_token: @refresh_token }
          )

          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            @access_token = data["access_token"]
            @refresh_token = data["refresh_token"]
            @dpop_handler = refresh_dpop
          else
            raise StandardError, "Failed to refresh token: #{response.code} - #{response.body}"
          end
        end
    end

  def base_url
    "https://bsky.social"  # ou via configuration
  end
end
