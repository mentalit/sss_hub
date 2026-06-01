class AddDateToTrackers < ActiveRecord::Migration[8.1]
  def change
     add_column :trackers, :date, :date
  end
end
