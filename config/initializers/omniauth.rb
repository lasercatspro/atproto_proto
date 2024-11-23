require "omniauth/atproto"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(:atproto,
    "#{Rails.application.config.app_url}/oauth/client-metadata.json",
    nil,
    {
      client_options: {
        site: "https://bsky.social",
        authorize_url: "https://bsky.social/oauth/authorize",
        token_url: "https://bsky.social/oauth/token"
      },
      client_private_key: AtprotoKeys.current_private_key,
      client_jwk: AtprotoKeys.current_jwk,
      pds_host: "https://bsky.social",
      dpop_private_key: OpenSSL::PKey::EC.generate("prime256v1")
    })
end
