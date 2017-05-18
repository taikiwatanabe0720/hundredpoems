class AddPidsToDestinations < ActiveRecord::Migration
  def change
    add_column :destinations, :pid, :integer
  end
end
