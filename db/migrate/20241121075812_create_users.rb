class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :handle
      t.string :atproto_uri
      t.string :did
      t.timestamps
    end
  end
end
