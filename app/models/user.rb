class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  validates :did, presence: true, uniqueness: true
  has_many :feed_items
  has_many :posts, through: :feed_items
  has_many :pds_tokens, dependent: :destroy

  def self.from_atproto(auth)
    user = find_or_create_by!(did: auth.info.did)
    token = user.pds_tokens.find_or_initialize_by(pds_host: auth.info.pds_host)
    token.token = auth.credentials.token
    token.expires_at = auth.credentials.expires_at
    token.refresh_token = auth.credentials.refresh_token
    token.save!
    user
  end
end
