class AddCountedToTrackers < ActiveRecord::Migration[8.1]
  def change
    add_column :trackers, :counted, :integer
  end
end