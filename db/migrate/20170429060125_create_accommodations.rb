class CreateAccommodations < ActiveRecord::Migration
  def change
    create_table :accommodations do |t|
      t.string :name
      t.decimal :longitude, precision: 10, scale: 5
      t.decimal :latitude, precision: 10, scale: 5
      t.string :url
      t.string :type

      t.timestamps null: false
    end
  end
end
