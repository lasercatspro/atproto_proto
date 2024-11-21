class GetPostsService
  def self.call(*, &block)
    new(*, &block).call
  end

  def initialize(handle)
    @handle = handle
  end

  def call = AtprotoClient.new(handle: @handle).posts_from_followed
end
