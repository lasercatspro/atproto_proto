class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :atproto_uri, null: false  # Original 'uri'
      t.string :cid          # Content identifier
      t.text :content        # Original 'text'
      t.string :type_name    # Original '$type'
      t.string :language     # Simplified from 'langs' array

      # Reply structure
      t.string :reply_root_cid
      t.string :reply_root_uri
      t.string :reply_parent_cid
      t.string :reply_parent_uri

      # Facets/Mentions
      t.json :facets         # Store facets as JSON for flexibility

      t.datetime :atproto_created_at  # Original 'createdAt'
      t.timestamps
    end

    add_index :posts, :atproto_uri, unique: true
    add_index :posts, :cid
    add_index :posts, :reply_root_uri
    add_index :posts, :reply_parent_uri
  end
end
