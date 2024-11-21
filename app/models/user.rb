class User < ApplicationRecord
  # validates :atproto_uri, uniqueness: true
  validates :handle, presence: true, uniqueness: true
  has_many :feed_items
  has_many :posts, through: :feed_items

  def add_to_feed(post) = feed_items.create!(post: post)

  def download_posts
    posts = GetPostsService.call(handle)
    posts.each do |p|
      Post.create!(p)
    rescue ActiveRecord::RecordInvalid => e
      puts e
    end
  end
end
