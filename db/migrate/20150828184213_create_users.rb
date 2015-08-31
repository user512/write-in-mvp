class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :token
      t.string :uid
      t.datetime :expires
      t.references :district

      t.timestamps null: false
    end
  end
end
