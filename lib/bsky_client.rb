require "atproto_client"
require "net/http"
require "async"

class BskyClient < AtprotoClient
  PDS_URL = "https://boletus.us-west.host.bsky.network"

  def query_lexicon(lexicon, params: {})
    make_api_request(
      :get,
      "#{PDS_URL}/xrpc/#{lexicon}",
      params:
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
