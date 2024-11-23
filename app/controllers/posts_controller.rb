class PostsController < ApplicationController
  def index
    # We should display posts from db, but for testing purposes, here are the posts of the current user.
    user = Current.user
    token = Current.user.pds_tokens.first
    bsky = BskyClient.new(token.token, token.refresh_token)
    @posts_from_the_internet = bsky.list_posts(user.did)

    # @posts_by_thread = Post.all
    #   .where.not(reply_root_uri: nil)
    #   .group_by(&:reply_root_uri)
    #   .sort_by { |_uri, posts| -posts.size }
    #   .first(10)
  end
end
