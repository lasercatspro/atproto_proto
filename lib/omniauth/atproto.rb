require "omniauth-oauth2"
require "json"
require "net/http"
require "dpop_handler"

module OmniAuth
  module Strategies
    class Atproto < OmniAuth::Strategies::OAuth2
      def initialize(app, *args)
        super
        @dpop_handler = DpopHandler.new(options.dpop_private_key)
      end

      info do
        {
          did: @access_token.params["sub"],
          pds_host: options.pds_host
        }
      end

      def authorize_params
        super.tap do |params|
          params[:scope] = "atproto"
          session["omniauth.pkce.verifier"] = pkce_verifier
          params[:code_challenge] = pkce_challenge
          params[:code_challenge_method] = "S256"
        end
      end

      private

      def build_access_token
        verifier = session.delete("omniauth.pkce.verifier")
        token_params = {
          grant_type: "authorization_code",
          redirect_uri: callback_url,
          code: request.params["code"],
          code_verifier: verifier,
          client_id: options.client_id,
          client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          client_assertion: generate_client_assertion
        }

        response = @dpop_handler.make_request(
          client.token_url,
          :post,
          headers: { "Content-Type" => "application/json", "Accept" => "application/json" },
          body: token_params
        )
        ::OAuth2::AccessToken.from_hash(client, JSON.parse(response.body))
      end

      def generate_client_assertion
        # Format : JWT signé avec la clé privée correspondant à la clé publique déclarée au format jwk sur le endpoint de metadata.json (client_private_key)

        raise "Client ID is required" unless options.client_id
        raise "Client JWK is required" unless options.client_jwk

        # Utiliser la clé privée stockée
        private_key = if options.client_private_key.is_a?(String)
          OpenSSL::PKey::EC.new(options.client_private_key)
        elsif options.client_private_key.is_a?(OpenSSL::PKey::EC)
          options.client_private_key
        else
          raise "Invalid client_private_key format"
        end

        # Construire le payload JWT
        jwt_payload = {
          iss: options.client_id,
          sub: options.client_id,
          aud: options.client_options.site,
          jti: SecureRandom.uuid,
          iat: Time.now.to_i,
          exp: Time.now.to_i + 300
        }

        # Utiliser le JWK déjà généré et stocké pour l'en-tête
        JWT.encode(
          jwt_payload,
          private_key,
          "ES256",
          {
            typ: "jwt",
            alg: "ES256",
            kid: options.client_jwk[:kid] # Utiliser le kid du JWK stocké
          }
        )
      end

      def pkce_verifier
        @pkce_verifier ||= SecureRandom.urlsafe_base64(64)
      end

      def pkce_challenge
        Base64.urlsafe_encode64(
          Digest::SHA256.digest(pkce_verifier),
          padding: false
        )
      end

      def callback_url
        full_host + callback_path
      end
    end
  end
end
