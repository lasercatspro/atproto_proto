class CreatePdsToken < ActiveRecord::Migration[8.0]
  def change
    create_table :pds_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :pds_host
      t.text :token
      t.text :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
