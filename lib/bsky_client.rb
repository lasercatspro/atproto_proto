require "atproto_client"
require "net/http"
require "async"

class BskyClient < AtProto::Client
  PDS_URL = "https://boletus.us-west.host.bsky.network"

  def query_lexicon(lexicon, params: {})
    make_api_request(
      :get,
      "#{PDS_URL}/xrpc/#{lexicon}",
      params:
    )
  end

  # High-level API methods
  def get_profile(handle)
    make_api_request(
      "GET",
      "#{base_url}/xrpc/app.bsky.actor.getProfile",
      params: { actor: handle }
    )
  end

  def create_post(text, reply_to: nil)
    body = {
      collection: "app.bsky.feed.post",
      repo: handle,
      record: {
        text: text,
        createdAt: Time.now.utc.iso8601,
        reply_to: reply_to
      }.compact
    }

    make_api_request(
      "POST",
      "#{base_url}/xrpc/com.atproto.repo.createRecord",
      body: body
    )
  end

  def list_records(did, collection)
    data = query_lexicon("com.atproto.repo.listRecords", params: { repo: did, collection: })
    data["records"]
  end

  def list_followed(did) = list_records(did, "app.bsky.graph.follow")

  def list_posts(did) = list_records(did, "app.bsky.feed.post")

  def get_post_thread(uri)
    query_lexicon("app.bsky.feed.getPostThread", params: { uri: })
  end
end
