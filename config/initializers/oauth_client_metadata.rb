require "fileutils"

Rails.application.config.after_initialize do
  metadata_path = Rails.public_path.join("oauth/client-metadata.json")
  FileUtils.mkdir_p(metadata_path.dirname)

  metadata = {
    client_id: "#{Rails.application.config.app_url}/oauth/client-metadata.json",
    application_type: "web",
    client_name: Rails.application.class.module_parent_name,
    client_uri: Rails.application.config.app_url,
    dpop_bound_access_tokens: true,
    grant_types: [ "authorization_code", "refresh_token" ],
    redirect_uris: [ "#{Rails.application.config.app_url}/auth/atproto/callback" ],
    response_types: [ "code" ],
    scope: "atproto",
    token_endpoint_auth_method: "private_key_jwt",
    token_endpoint_auth_signing_alg: "ES256",
    jwks: {
      keys: [ AtprotoKeys.current_jwk ]
    }
  }

  File.write(metadata_path, JSON.pretty_generate(metadata))
end
