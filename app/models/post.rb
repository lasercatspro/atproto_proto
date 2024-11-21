class Post < ApplicationRecord
  validates :atproto_uri, presence: true, uniqueness: true
  validates :content, presence: true
  validates :type_name, presence: true
  has_many :feed_items
  has_many :users, through: :feed_items

  # Helper method to get mentions from facets
  # Claude did this, didnt have time to check
  def mentions
    return [] if facets.blank?

    facets.filter { |f| f["$type"] == "app.bsky.richtext.facet" }
          .flat_map { |f| f["features"] }
          .filter { |f| f["$type"] == "app.bsky.richtext.facet#mention" }
          .map { |f| f["did"] }
  end

  # Helper method to check if post is a reply
  def reply? = reply_parent_uri.present?
end
