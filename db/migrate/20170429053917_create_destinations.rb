class CreateDestinations < ActiveRecord::Migration
  def change
    create_table :destinations do |t|
      t.string :name
      t.decimal :longitude, precision: 10, scale: 5
      t.decimal :latitude, precision: 10, scale: 5

      t.timestamps null: false
    end
  end
end
