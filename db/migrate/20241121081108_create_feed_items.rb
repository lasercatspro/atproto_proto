class CreateFeedItems < ActiveRecord::Migration[8.0]
  def change
    create_table :feed_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    add_index :feed_items, [ :user_id, :post_id ], unique: true
  end
end
