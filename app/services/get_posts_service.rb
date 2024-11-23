class GetPostsService
  def self.call(*, &block)
    new(*, &block).call
  end

  def initialize(handle)
    @handle = handle
  end

  def call
    bob = AtprotoClient::Scrapper.new(pds_url, list_followed.map { |f| f.dig("value", "subject") })
    bob.posts_from_followed
    bob.posts.values
  end
end
