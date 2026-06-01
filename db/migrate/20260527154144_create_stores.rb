class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.string :Storename
      t.integer :storenum

      t.timestamps
    end
  end
end
