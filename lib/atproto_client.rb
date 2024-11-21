# require "skyfall"

require "net/http"
require "async"

class AtprotoClient
  def initialize(handle: nil, did: nil)
    @handle = handle
    @did = did
  end

  def did
    host = URI("https://#{@handle}").host || @handle

    @did ||= begin
      response = Net::HTTP.get(URI("https://#{host}/.well-known/atproto-did"))
      return response.strip if response
    rescue e
      puts e
      "did:plc:#{@handle}"
    end
  end

  def base_uri = @uri ||= URI("https://plc.directory/#{did}")

  def lookup_profile = JSON.parse(Net::HTTP.get(base_uri))

  def pds_url
    url = lookup_profile.dig("service").find { |s| s["id"] == "#atproto_pds" }
    url["serviceEndpoint"]
  end

  def list_records(collection)
    uri = URI("#{pds_url}/xrpc/com.atproto.repo.listRecords")
    params = { repo: did, collection: }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  def list_followed
    data = list_records("app.bsky.graph.follow")
    data["records"].map do |record|
      {
        did: record["value"]["subject"],
        created_at: record["value"]["createdAt"],
        rkey: record["rkey"]
      }
    end
  end

  def list_posts
    data = list_records("app.bsky.feed.post")

    data["records"].map do |record|
      {
        atproto_uri: record.dig("uri"),
        cid: record.dig("cid"),
        content: record.dig("value", "text") || "",
        type_name: record.dig("value", "$type"),
        language: record.dig("value", "langs")&.first,
        reply_root_cid: record.dig("value", "reply", "root", "cid"),
        reply_root_uri: record.dig("value", "reply", "root", "uri"),
        reply_parent_cid: record.dig("value", "reply", "parent", "cid"),
        reply_parent_uri: record.dig("value", "reply", "parent", "uri"),
        facets: record.dig("value", "facets"),
        atproto_created_at: record.dig("value", "createdAt")
      }
    end
  end

  def posts_from_followed
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    list = Async do |task|
      followed = list_followed

      # Create an array of promises
      promises = followed.map do |f|
        task.async do
          puts "Fetching posts for #{f[:did]}"
          AtprotoClient.new(did: f[:did]).list_posts
        end
      end

      # Wait for all promises to complete and collect results
      results = promises.map(&:wait)
      results.flatten
    end.wait

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    puts "Total time: #{end_time - start_time} seconds"
    list
  end
end
